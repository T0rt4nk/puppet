FROM alpine:3.4

WORKDIR /tmp

RUN apk add --update alpine-sdk perl xz-dev syslinux bash && \
      git clone git://git.ipxe.org/ipxe.git

WORKDIR /tmp/ipxe/src

RUN sed -i 's/\/\/\(\#define PING_CMD.*\)/\1/' config/general.h

ENTRYPOINT ["/usr/bin/make"]

CMD []
