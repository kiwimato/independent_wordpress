FROM alpine:3.10 as rootfs-stage

# environment
ENV REL=v3.12
ENV ARCH=x86_64
ENV MIRROR=http://dl-cdn.alpinelinux.org/alpine
ENV PACKAGES=alpine-baselayout,\
alpine-keys,\
apk-tools,\
busybox,\
libc-utils,\
xz

# install packages
RUN \
  apk add --no-cache \
    bash \
    curl \
    tzdata \
    xz

# fetch builder script from gliderlabs
RUN \
  curl -o \
    /mkimage-alpine.bash -L \
    https://raw.githubusercontent.com/gliderlabs/docker-alpine/master/builder/scripts/mkimage-alpine.bash && \
  chmod +x \
	  /mkimage-alpine.bash && \
    ./mkimage-alpine.bash  && \
  mkdir /root-out && \
  tar xf \
	  /rootfs.tar.xz -C \
	  /root-out && \
  sed -i -e 's/^root::/root:!:/' /root-out/etc/shadow

# Runtime stage
FROM scratch
COPY --from=rootfs-stage /root-out/ /
ARG BUILD_DATE
ARG VERSION
ARG CERTBOT_VERSION
LABEL build_version="Linuxserver.io version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="kiwimato"

# set version for s6 overlay
ARG OVERLAY_VERSION="v2.0.0.1"
ARG OVERLAY_ARCH="amd64"

# environment variables
ENV PS1="$(whoami)@$(hostname):$(pwd)\\$ " \
    HOME="/root" \
    TERM="xterm"

RUN \
  echo "**** install build packages ****" && \
  apk add --no-cache --virtual=build-dependencies \
	  curl \
    g++ \
    gcc \
    libffi-dev \
    openssl-dev \
    python3-dev \
	  tar && \
  echo "**** install runtime packages ****" && \
  apk add --no-cache \
    bash \
    ca-certificates \
    coreutils \
    procps \
    shadow \
    apache2-utils \
    git \
    libressl3.1-libssl \
    logrotate \
    nano \
    nginx \
    openssl \
    php7 \
    php7-fileinfo \
    php7-fpm \
    php7-json \
    php7-mbstring \
    php7-openssl \
    php7-session \
    php7-simplexml \
    php7-xml \
    php7-xmlwriter \
    php7-zlib \
    curl \
    fail2ban \
    gnupg \
    memcached \
    nginx \
    nginx-mod-http-echo \
    nginx-mod-http-fancyindex \
    nginx-mod-http-geoip2 \
    nginx-mod-http-headers-more \
    nginx-mod-http-image-filter \
    nginx-mod-http-lua \
    nginx-mod-http-lua-upstream \
    nginx-mod-http-nchan \
    nginx-mod-http-perl \
    nginx-mod-http-redis2 \
    nginx-mod-http-set-misc \
    nginx-mod-http-upload-progress \
    nginx-mod-http-xslt-filter \
    nginx-mod-mail \
    nginx-mod-rtmp \
    nginx-mod-stream \
    nginx-mod-stream-geoip2 \
    nginx-vim \
    php7-bcmath \
    php7-bz2 \
    php7-ctype \
    php7-curl \
    php7-dom \
    php7-exif \
    php7-ftp \
    php7-gd \
    php7-iconv \
    php7-imap \
    php7-intl \
    php7-ldap \
    php7-mcrypt \
    php7-memcached \
    php7-mysqli \
    php7-mysqlnd \
    php7-opcache \
    php7-pdo_mysql \
    php7-pdo_odbc \
    php7-pdo_pgsql \
    php7-pdo_sqlite \
    php7-pear \
    php7-pecl-apcu \
    php7-pecl-redis \
    php7-pgsql \
    php7-phar \
    php7-posix \
    php7-soap \
    php7-sockets \
    php7-sodium \
    php7-sqlite3 \
    php7-tokenizer \
    php7-xml \
    php7-xmlreader \
    php7-xmlrpc \
    php7-zip \
    py3-cryptography \
    py3-future \
    py3-pip \
    whois \
    tzdata && \
  echo "**** add s6 overlay ****" && \
  curl -o \
    /tmp/s6-overlay.tar.gz -L \
	  "https://github.com/just-containers/s6-overlay/releases/download/${OVERLAY_VERSION}/s6-overlay-${OVERLAY_ARCH}.tar.gz" && \
  tar xfz \
	  /tmp/s6-overlay.tar.gz -C / && \
  echo "**** create abc user and make our folders ****" && \
  groupmod -g 1000 users && \
  useradd -u 911 -U -d /config -s /bin/false abc && \
  usermod -G users abc && \
  mkdir -p \
    /app \
    /config \
    /defaults && \
  mv /usr/bin/with-contenv /usr/bin/with-contenvb

# configure nginx
RUN \
  echo "**** configure nginx ****" && \
  echo 'fastcgi_param  SCRIPT_FILENAME $document_root$fastcgi_script_name;' >> \
	  /etc/nginx/fastcgi_params && \
  rm -f /etc/nginx/conf.d/default.conf && \
  echo "**** fix logrotate ****" && \
  sed -i "s#/var/log/messages {}.*# #g" /etc/logrotate.conf && \
  sed -i 's#/usr/sbin/logrotate /etc/logrotate.conf#/usr/sbin/logrotate /etc/logrotate.conf -s /config/log/logrotate.status#g' \
	  /etc/periodic/daily/logrotate

# environment settings
ENV DHLEVEL=2048 ONLY_SUBDOMAINS=false AWS_CONFIG_FILE=/config/dns-conf/route53.ini
ENV S6_BEHAVIOUR_IF_STAGE2_FAILS=2

RUN \
  echo "**** install certbot plugins ****" && \
  if [ -z ${CERTBOT_VERSION+x} ]; then \
    CERTBOT="certbot"; \
  else \
    CERTBOT="certbot==${CERTBOT_VERSION}"; \
  fi && \
  pip3 install -U \
	  pip \
	  wheel && \
  pip3 install -U \
    ${CERTBOT} \
    certbot-dns-aliyun \
    certbot-dns-cloudflare \
    certbot-dns-cloudxns \
    certbot-dns-cpanel \
    certbot-dns-digitalocean \
    certbot-dns-dnsimple \
    certbot-dns-dnsmadeeasy \
    certbot-dns-domeneshop \
    certbot-dns-google \
    certbot-dns-inwx \
    certbot-dns-linode \
    certbot-dns-luadns \
    certbot-dns-nsone \
    certbot-dns-ovh \
    certbot-dns-rfc2136 \
    certbot-dns-route53 \
    certbot-dns-transip \
    certbot-plugin-gandi \
    cryptography \
    requests && \
  echo "**** remove unnecessary fail2ban filters ****" && \
  rm \
	  /etc/fail2ban/jail.d/alpine-ssh.conf && \
  echo "**** copy fail2ban default action and filter to /default ****" && \
  mkdir -p /defaults/fail2ban && \
  mv /etc/fail2ban/action.d /defaults/fail2ban/ && \
  mv /etc/fail2ban/filter.d /defaults/fail2ban/ && \
  echo "**** copy proxy confs to /default ****" && \
  mkdir -p /defaults/proxy-confs && \
  curl -o \
	  /tmp/proxy.tar.gz -L \
  	"https://github.com/linuxserver/reverse-proxy-confs/tarball/master" && \
  tar xf \
    /tmp/proxy.tar.gz -C \
	  /defaults/proxy-confs --strip-components=1 --exclude=linux*/.gitattributes --exclude=linux*/.github --exclude=linux*/.gitignore --exclude=linux*/LICENSE && \
  echo "**** configure nginx ****" && \
  rm -f /etc/nginx/conf.d/default.conf && \
  curl -o \
    /defaults/dhparams.pem -L \
	  "https://lsio.ams3.digitaloceanspaces.com/dhparams.pem" && \
  echo "**** cleanup ****" && \
  apk del --purge \
	  build-dependencies && \
  for cleanfiles in *.pyc *.pyo; \
	do \
	  find /usr/lib/python3.*  -iname "${cleanfiles}" -exec rm -f '{}' + \
	; done && \
  rm -rf \
    /tmp/* \
    /root/.cache

# add local files
COPY root/ /

EXPOSE 80 443
VOLUME /config

ENTRYPOINT ["/init"]