# Latest Ubuntu LTS
FROM ubuntu:14.04

MAINTAINER  Erik Osterman "e@osterman.com"

# Confd
ENV ETCD_HOST 172.17.42.1
ENV ETCD_PORT 4001
ENV CONFD_INTERVAL 60
ENV CONFD_VERSION 0.9.0
ENV CONFD_PREFIX /containers/something

# System 
ENV TIMEZONE Etc/UTC
ENV DEBIAN_FRONTEND noninteractive
ENV VARNISH_NAME default
ENV VARNISH_CANONICAL_HOST default
ENV VARNISH_BACKEND_HOST localhost
ENV VARNISH_BACKEND_PORT 80
ENV VARNISH_BACKEND_CONNECT_TIMEOUT 5s
ENV VARNISH_BACKEND_FIRST_BYTE_TIMEOUT 600s
ENV VARNISH_BACKEND_BETWEEN_BYTES_TIMEOUT 20s
ENV VARNISH_PROBE_REQUEST "GET / HTTP/1.1"
ENV VARNISH_PROBE_HOST localhost
ENV VARNISH_PROBE_WINDOW 5
ENV VARNISH_PROBE_THRESHOLD 3
ENV VARNISH_PROBE_INTERVAL 5s
ENV VARNISH_PROBE_TIMEOUT 15000ms
ENV VARNISH_GRACE_HEALTHY 600s
ENV VARNISH_GRACE_UNHEALTHY 48h
ENV VARNISH_TTL_CONTENT 300s
ENV VARNISH_TTL_ASSETS 1d

ENV VARNISH_CONFIG_TEMPLATE default.vcl.m4
#ENV VARNISH_CONFIG_TEMPLATE wp.vcl.m4
ENV VARNISH_STORAGE 1G
ENV VARNISH_THREAD_POOLS 25
ENV VARNISH_THREAD_POOL_MIN 100
ENV VARNISH_CLI_TIMEOUT 86400
ENV VARNISH_SESS_TIMEOUT 30

ADD https://github.com/kelseyhightower/confd/releases/download/v$CONFD_VERSION/confd-$CONFD_VERSION-linux-amd64 /usr/bin/confd

RUN apt-get update && \
    apt-get install -y apt-transport-https curl m4 && \
    curl -s https://repo.varnish-cache.org/GPG-key.txt | apt-key add - && \
    echo "deb https://repo.varnish-cache.org/ubuntu/ trusty varnish-4.0" >> /etc/apt/sources.list.d/varnish-cache.list && \
    apt-get update && \
    apt-get install -y varnish && \
    apt-get clean && \
    touch /var/run/varnishd.pid && \
    chown varnish:varnish -R /var/lib/varnish/ /var/run/varnishd.pid /etc/varnish/secret && \
    chmod 755 /usr/bin/confd && \
    sed -i 's/^ulimit/#ulimit/' /etc/init.d/varnish

ADD varnish /varnish
ADD confd/ /etc/confd

ENV TERM xterm

USER root

EXPOSE 80
EXPOSE 6082

ADD default.vcl.m4 /etc/varnish/
ADD wp.vcl.m4 /etc/varnish/

CMD /varnish

