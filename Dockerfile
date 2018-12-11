FROM alpine:3.8

LABEL maintainer="Carlos Remuzzi <carlosremuzzi@gmail.com>"
LABEL version="0.19.0"

ARG LIBP11_VERSION=0.4.8

WORKDIR /usr/src/build

RUN apk add --no-cache \
        ccid \
        pcsc-lite \
        pcsc-lite-dev \
    && apk add --no-cache --virtual .build-deps \
        autoconf \
        automake \
        build-base \
        curl \
        gettext \
        libressl-dev \
        libtool \
        m4 \
        readline-dev \
        zlib-dev \
    && curl -fsL https://github.com/OpenSC/OpenSC/releases/download/0.19.0/opensc-0.19.0.tar.gz  -o opensc-0.19.0.tar.gz \
    && tar -zxf opensc-0.19.0.tar.gz \
    && rm opensc-0.19.0.tar.gz \
    && cd opensc-0.19.0 \
    && ./bootstrap \
    && ./configure \
        --host=x86_64-alpine-linux-musl \
        --prefix=/usr \
        --sysconfdir=/etc \
        --disable-man \
        --enable-zlib \
        --enable-readline \
        --enable-openssl \
        --enable-pcsc \
        --enable-sm \
        CC='gcc' \
    && make \
    && make install

RUN curl -fsL https://github.com/OpenSC/libp11/releases/download/libp11-${LIBP11_VERSION}/libp11-${LIBP11_VERSION}.tar.gz -o libp11-${LIBP11_VERSION}.tar.gz \
    && tar -zxf libp11-${LIBP11_VERSION}.tar.gz \
    && rm libp11-${LIBP11_VERSION}.tar.gz \
    && cd libp11-${LIBP11_VERSION} \
    && ./configure \
        --host=x86_64-alpine-linux-musl \
#        CFLAGS='-Wno-traditional -Wno-error -Werror=declaration-after-statement' \
        CFLAGS='-Wno-error -Wno-traditional -Werror=declaration-after-statement' \
        CC='gcc' \
    && make \
    && make install

RUN apk del .build-deps \
    && rm -r /usr/src/build \
    && addgroup -g 1000 opensc \
    && adduser -u 1000 -G opensc -s /bin/sh -D opensc \
    && mkdir -p /run/pcscd \
    && chown -R nobody:nobody /run/pcscd

WORKDIR /

CMD ["pcscd","-f","-i"]
