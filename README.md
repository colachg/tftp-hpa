# tftp-hpa
[![build-image](https://github.com/colachg/tftp-hpa/actions/workflows/build-image.yml/badge.svg)](https://github.com/colachg/tftp-hpa/actions/workflows/build-image.yml)

PXELinux is a network boot server and can be used as a replacement to boot CDs or USB. Devices boot from the network and the PXELinux server provides the bootstrap files. Often this is used to deploy new installations of Linux when a system boots.

## quick start

- `docker-compose up -d` to start but you need to download netboot.tar.gz first. It is about 53MB so I didn't add it to git.
- nginx is used to as a http server to provide ks.cfg here. you can modify the `default.conf` as you want.
- `ks.conf` is in `os/ubuntu/bionic`

## PXELinux using Proxy DHCP

### Install packages

We will install the package dnsmasq as this provides DNS, DHCP, DHCP Proxy and TFTP services with the single package and single service. This is very much designed with PXELinux in mind as we want DHCP and TFTP or as we will use TFTP with Proxy DHCP. Along with this we want the package pxelinux and its sister package syslinux. Pxelinux provides network boot and syslinux provides boot mechanisms from hard disk, iso file systems and USB drives. The package systenlix provides a lot of the shared files that we need for booting to any medium.

```shell
sudo apt update
sudo apt install pxelinux syslinux dnsmasq
```

If you have already installed dnsmasq in your LAN, you don't need to install dnsmasq.

### Configure the dnsmasq

```shell
$ sudo vim /etc/dnsmasq.conf
...
dhcp-boot=pxelinux.0
pxe-service=x86PC,'Network Boot',pxelinux
enable-tftp
tftp-root=/tftpboot
...
```

- dhcp-boot=pxelinux.0: Set the DHCP Option for the boot filename used as the network bootstrap file
- pxe-service=x86PC,’Network Boot’,pxelinux : Here we set the 2nd DHCP Option we deliver to DHCP clients and specify this is for our bios based systems, x86PC, a boot message and the name of the bootstrap file omitting the .0 from the end of the name.
- enable-tftp : We need the TFTP server to deliver files after the bootstrap files has been delivered by PXELinux using Proxy DHCP.
- tftp-root=/tftpboot : We set the path to the root directory that will be used by the TFTP Server

### Populate the TFTP Root

We now need to make sure the the bootstrap file that the DHCP options refer to is present. We will also need some other files from the system Linux package. We will add these all to the /tftpboot directory we have recently created.

- `sudo mkdir -p /tftpboot/pxelinux.cfg`
- `sudo cp /usr/lib/PXELINUX/pxelinux.0 /tftpboot/`
- `sudo cp /usr/lib/syslinux/modules/bios/{menu,ldlinux,libmenu,libutil}.c32 /tftpboot/`

```shell
ls -l /tftpboot
total 240
-rw-r--r-- 1 developer developer 115820 Dec 24 16:28 ldlinux.c32
-rw-r--r-- 1 developer developer  23972 Dec 24 16:28 libmenu.c32
-rw-r--r-- 1 developer developer  23056 Dec 24 16:28 libutil.c32
-rw-r--r-- 1 developer developer  26236 Dec 24 16:28 menu.c32
-rw-r--r-- 1 root      root       41612 Dec 24 16:24 pxelinux.0
drwxr-xr-x 2 developer developer   4096 Dec 24 16:26 pxelinux.cfg
```

## PXE Install Ubuntu 18.04

### Download the Ubuntu Installer for PXE Install Ubuntu 18.04

Firstly, we can download the Ubuntu 18.04 installer. This is compressed file that contains all the files necessary for the PXE Server. As we have an existing PXE Server we just need to use the Ubuntu kernel and RAM disk. To download the file, work within your home directory and run the following command.

`wget http://archive.ubuntu.com/ubuntu/ubuntu/dists/bionic/main/installer-amd64/current/images/netboot/netboot.tar.gz -O bionic-netboot.tar.gz`

Keeping everything tidy we will create a directory and expand the archive into the directory:

```
mkdir ~/bionic-netboot
tar zxf bionic-netboot.tar.gz -C ~/bionic-netboot
```

### Copy the install kernel and RAM disk

Having expanded the installed archive we now need to add the boot files to the TFTP Server. As we may install many Linux distributions we will keep these files in their own sub-directory within the root directory for the TFTP Server. For us, this was the directory /tftpboot. The two files we copy are linux, the kernel and initrd.gz the RAM disk. By Enclosing the two files within the brace brackets we can reduce the code to copy.

```
sudo mkdir /tftpboot/bionic/
sudo cp bionic-netboot/ubuntu-installer/amd64/{linux,initrd.gz} /tftpboot/bionic/
```

### Modify the PXE configuration

The final task we need to complete is to update the PXE Linux configuration file.
Adding a new stanza to PXE Install Ubuntu 18.04 will allow the options we need. The file we are editing is the default file. This can be found on out system at /tftpboot/pxelinux.cfg/default. We will append to the original content. The edited the file should read as the following.

```
default menu.c32
prompt 0
menu title Boot Menu
  label localboot
    menu label Boot Local Disk
    localboot 0

  label bionic
    menu label Manual Install Ubuntu 18.04 Server
    kernel bionic/linux
    append initrd=bionic/initrd.gz vga=788 locale=en_GB.UTF-8 keyboard-configuration/layoutcode=gb hostname=ubuntu

```

### Add kickstart configuration

Repetition is boring so it's necessary to make it automatically.

`sudo apt install -y system-config-kickstart`

After generating kickstart configuration you may add it to pxe configuration.

```
default menu.c32
prompt 0
menu title Boot Menu
  label localboot
    menu label Boot Local Disk
    localboot 0

  label bionic
    menu label Manual Install Ubuntu 18.04 Server
    kernel bionic/linux
    append initrd=bionic/initrd.gz vga=788 locale=en_GB.UTF-8 keyboard-configuration/layoutcode=gb hostname=ubuntu ks=http://http-server-ip/ubuntu/bionic/ks.cfg
```

Finally, if all are right you can plug in cable to bare metal machine and enjoy your coffee.
