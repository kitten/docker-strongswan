FROM buildpack-deps:jessie

RUN mkdir -p /conf

RUN apt-get update && apt-get install -y \
  libgmp-dev \
  iptables \
  xl2tpd

ENV STRONGSWAN_VERSION 5.3.4

RUN mkdir -p /usr/src/strongswan \
	&& curl -SL "https://download.strongswan.org/strongswan-$STRONGSWAN_VERSION.tar.gz" \
	| tar -zxC /usr/src/strongswan --strip-components 1 \
	&& cd /usr/src/strongswan \
	&& ./configure --prefix=/usr --sysconfdir=/etc \
		--enable-eap-radius \
		--enable-eap-mschapv2 \
		--enable-eap-identity \
		--enable-eap-md5 \
		--enable-eap-mschapv2 \
		--enable-eap-tls \
		--enable-eap-ttls \
		--enable-eap-peap \
		--enable-eap-tnc \
		--enable-eap-dynamic \
		--enable-xauth-eap \
		--enable-openssl \
	&& make \
	&& make install \
	&& rm -rf /usr/src/strongswan

# Strongswan Configuration
ADD ipsec.conf /etc/ipsec.conf
ADD strongswan.conf /etc/strongswan.conf

# XL2TPD Configuration
ADD xl2tpd.conf /etc/xl2tpd/xl2tpd.conf
ADD options.xl2tpd /etc/ppp/options.xl2tpd

ADD run.sh /run.sh
ADD vpn_adduser /usr/local/bin/vpn_adduser
ADD vpn_deluser /usr/local/bin/vpn_deluser
ADD vpn_setpsk /usr/local/bin/vpn_setpsk
ADD vpn_unsetpsk /usr/local/bin/vpn_unsetpsk

# The password is later on replaced with a random string
ENV VPN_USER user
ENV VPN_PASSWORD password
ENV VPN_PSK password

VOLUME ["/etc/ipsec.d"]

EXPOSE 4500/udp 500/udp 1701/udp

CMD ["/run.sh"]
