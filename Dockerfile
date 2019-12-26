FROM alpine
LABEL MAINTAINER=colachg@gmail.com

RUN apk add --no-cache tini tftp-hpa nginx supervisor &&\
    mkdir -p /run/nginx

EXPOSE 69/udp 80

COPY supervisord.conf /etc/supervisord.conf

ENTRYPOINT ["/sbin/tini", "--"]

CMD [ "/usr/bin/supervisord", "-c", "/etc/supervisord.conf" ]
