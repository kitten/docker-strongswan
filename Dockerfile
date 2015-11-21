FROM buildpack-deps:jessie

RUN mkdir -p /conf

RUN apt-get update && apt-get install -y \
  libgmp-dev \
  iptables

ENV STRONGSWAN_VERSION 5.3.4

RUN mkdir -p /usr/src/strongswan \
	&& curl -SL "https://download.strongswan.org/strongswan-$STRONGSWAN_VERSION.tar.gz" \
	| tar -zxC /usr/src/strongswan --strip-components 1 \
	&& cd /usr/src/strongswan \
	&& ./configure --prefix=/usr --sysconfdir=/etc --enable-kernel-libipsec \
	&& make \
	&& make install \
	&& rm -rf /usr/src/strongswan

# Configuration files
ADD ipsec.conf /etc/ipsec.conf
ADD strongswan.conf /etc/strongswan.conf
ADD run.sh /run.sh

# The password is later on replaced with a random string
ENV VPN_USER user
ENV VPN_PASSWORD password
ENV VPN_PSK password

VOLUME ["/etc/ipsec.d"]
EXPOSE 4500/udp 500/udp

CMD ["/run.sh"]