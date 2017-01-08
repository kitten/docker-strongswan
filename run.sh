#!/bin/bash

sysctl -w net.ipv4.conf.all.rp_filter=2

iptables --table nat --append POSTROUTING --jump MASQUERADE
echo 1 > /proc/sys/net/ipv4/ip_forward
for each in /proc/sys/net/ipv4/conf/*
do
	echo 0 > $each/accept_redirects
	echo 0 > $each/send_redirects
done

if [ "$VPN_PASSWORD" = "password" ] || [ "$VPN_PASSWORD" = "" ]; then
	# Generate a random password
	P1=`cat /dev/urandom | tr -cd abcdefghjkmnpqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789 | head -c 3`
	P2=`cat /dev/urandom | tr -cd abcdefghjkmnpqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789 | head -c 3`
	P3=`cat /dev/urandom | tr -cd abcdefghjkmnpqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789 | head -c 3`
	VPN_PASSWORD="$P1$P2$P3"
	echo "No VPN_PASSWORD set! Generated a random password: $VPN_PASSWORD"
fi

if [ "$VPN_PSK" = "password" ] || [ "$VPN_PSK" = "" ]; then
	# Generate a random password
	P1=`cat /dev/urandom | tr -cd abcdefghjkmnpqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789 | head -c 3`
	P2=`cat /dev/urandom | tr -cd abcdefghjkmnpqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789 | head -c 3`
	P3=`cat /dev/urandom | tr -cd abcdefghjkmnpqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789 | head -c 3`
	VPN_PSK="$P1$P2$P3"
	echo "No VPN_PSK set! Generated a random PSK key: $VPN_PSK"
fi

if [ "$VPN_PASSWORD" = "$VPN_PSK" ]; then
	echo "It is not recommended to use the same secret as password and PSK key!"
fi

cat > /etc/ppp/l2tp-secrets <<EOF
# This file holds secrets for L2TP authentication.
# Username  Server  Secret  Hosts

"$VPN_USER" "*" "$VPN_PASSWORD" "*"
EOF

cat > /etc/ipsec.secrets <<EOF
# This file holds shared secrets or RSA private keys for authentication.
# RSA private key for this host, authenticating it to any other host
# which knows the public part.  Suitable public keys, for ipsec.conf, DNS,
# or configuration of other implementations, can be extracted conveniently
# with "ipsec showhostkey".

: PSK "$VPN_PSK"

$VPN_USER : EAP "$VPN_PASSWORD"
$VPN_USER : XAUTH "$VPN_PASSWORD"
EOF

if [ -f "/etc/ipsec.d/l2tp-secrets" ]; then
	echo "Overwriting standard /etc/ppp/l2tp-secrets with /etc/ipsec.d/l2tp-secrets"
	cp -f /etc/ipsec.d/l2tp-secrets /etc/ppp/l2tp-secrets
fi

if [ -f "/etc/ipsec.d/ipsec.secrets" ]; then
	echo "Overwriting standard /etc/ipsec.secrets with /etc/ipsec.d/ipsec.secrets"
	cp -f /etc/ipsec.d/ipsec.secrets /etc/ipsec.secrets
fi

if [ -f "/etc/ipsec.d/ipsec.conf" ]; then
	echo "Overwriting standard /etc/ipsec.conf with /etc/ipsec.d/ipsec.conf"
	cp -f /etc/ipsec.d/ipsec.conf /etc/ipsec.conf
fi

if [ -f "/etc/ipsec.d/strongswan.conf" ]; then
	echo "Overwriting standard /etc/strongswan.conf with /etc/ipsec.d/strongswan.conf"
	cp -f /etc/ipsec.d/strongswan.conf /etc/strongswan.conf
fi

if [ -f "/etc/ipsec.d/xl2tpd.conf" ]; then
	echo "Overwriting standard /etc/xl2tpd/xl2tpd.conf with /etc/ipsec.d/xl2tpd.conf"
	cp -f /etc/ipsec.d/xl2tpd.conf /etc/xl2tpd/xl2tpd.conf
fi

mkdir -p /var/run/xl2tpd

exec /usr/bin/supervisord -c /supervisord.conf
