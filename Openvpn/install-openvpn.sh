#!/bin/bash 
# Samuel AUBERTIN

# Check if our kernel supports TUN devices
test ! -c /dev/net/tun && echo openvpn requires tun support || echo tun is available

# Install the thing
apt-get install openvpn zip

# Add an easy-rsa dir
mdkir /etc/openvpn/easy-rsa/ 
cp -pr /usr/share/easy-rsa /etc/openvpn/easy-rsa
cd /etc/openvpn/easy-rsa 

# New easy-rsa config 
# 2048b key (1024 too short now, 4096 a bit too cpu consuming on smartphones)
# 10 years expiration
cp vars{,.orig}
echo '
export EASY_RSA="`pwd`"
export OPENSSL="openssl"
export PKCS11TOOL="pkcs11-tool"
export GREP="grep"
export KEY_CONFIG=`$EASY_RSA/whichopensslcnf $EASY_RSA`
export KEY_DIR="$EASY_RSA/keys"
export PKCS11_MODULE_PATH="dummy"
export PKCS11_PIN="dummy"
export CA_EXPIRE=3650
export KEY_EXPIRE=3650
export KEY_SIZE=2048
export KEY_COUNTRY="FR"
export KEY_PROVINCE="FR"
export KEY_CITY="Paris"
export KEY_ORG="it-science.fr"
export KEY_EMAIL="root@it-science.fr"' > ./vars 

# Generating SSL things (CA + server + Diffie Helman)
source ./vars
./clean-all
./build-ca
./build-key-server it-science.fr  
./build-dh

# Generating the PSK key for TLS signature
openvpn --genkey --secret /etc/openvpn/easy-rsa/keys/ta.key

# Tidying !
mkdir -p /etc/openvpn/certs
cp -pv /etc/openvpn/easy-rsa/keys/{ca.{crt,key},it-science.fr.{crt,key},ta.key,dh2048.pem} /etc/openvpn/certs/

# The server configuration !
# Listening on 0.0.0.0:1194 and using UDP, because TCP is bad for tunnels U KNOW.
# The virtual network range is 192.168.88.0/24 and the default router becames the VPN server.
# DHCP pushes it-science.fr domain and the 10.0.2.2 DNS server.conf.
# DHCP also specifies Windows clients to disable NetBios on this network.
# We want the clients to communicate together so we put client-to-client option.
# We ping the server every 1800 sec (30 min) and consider it down once 4000 sec (66 min) (smartphones U KNOW).
# Auth is made with SHA512, crypto with AES 128 (FOR smartphones !!!)
# TLS with ephemeral Diffie Helman + RSA + AES256 + SHA 
# We add LZO compression for bandwith usage.
# We add some more security, logging
echo '
port 1194
proto udp
dev tun

ca /etc/openvpn/certs/ca.crt
cert /etc/openvpn/certs/it-science.fr.crt
key /etc/openvpn/certs/it-science.fr.key
dh /etc/openvpn/certs/dh2048.pem
tls-auth /etc/openvpn/certs/ta.key 0

server 192.168.88.0 255.255.255.0
ifconfig-pool-persist ipp.txt
push "route 192.168.88.8 255.255.255.0"
push "redirect-gateway def1 bypass-dhcp"
push "dhcp-option DNS 10.0.2.2"
push "dhcp-option DISABLE-NBT"
push "dhcp-option DOMAIN it-science.fr"

client-to-client
keepalive 1800 4000

auth SHA512
cipher AES-128-CBC
tls-cipher DHE-RSA-AES256-SHA 

comp-lzo

max-clients 100
user nobody
group nogroup
persist-key
persist-tun
log /var/log/openvpn.log
status /var/log/openvpn-status.log
verb 5
mute 20' > /etc/openvpn/server.conf

# Registering openvpn service 
update-rc.d -f openvpn defaults

# VPN server becomes a router
sed -i 's/^#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf 
sysctl -p


# Creating the clients directory
mkdir /etc/openvpn/clients/
cp -p /etc/openvpn/easy-rsa/keys/{ca.crt,ta.key} /etc/openvpn/clients
mkdir /etc/openvpn/zip/
service openvpn restart
