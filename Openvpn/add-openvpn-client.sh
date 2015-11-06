#!/bin/bash 
# Samuel Aubertin
if [[ -z "$1" ]]
then
	echo "First parameter (username) missing..."
	exit
fi

echo "Adding $1 to OpenVPN clients."
echo "Samuel Aubertin - 2014"
echo "Enter to continue, Ctrl+C to leave"
read

# Lets go to the easyy-rsa dir and get server config
cd /etc/openvpn/easy-rsa 
source ./vars

# Now lets generate a SSL key for our client 
./build-key $1

# Client config
# Same conf as server, with more :
# nobind so clients don't have to bind to a specific port
# auth-nocache because we don't use passwords anyway
# And certs are imported in the only .ovpn file
echo "
client
dev tun
proto udp
remote it-science.fr 1194
resolv-retry infinite
auth SHA512
cipher AES-128-CBC
tls-cipher DHE-RSA-AES256-SHA
key-direction 1
comp-lzo yes
nobind
auth-nocache
script-security 2
persist-key
persist-tun
user nobody
group nogroup" > /etc/openvpn/clients/$1.ovpn

# Copy keys to client conf
echo -e "<ca>\n$(cat /etc/openvpn/easy-rsa/keys/ca.crt)\n</ca>" >> /etc/openvpn/clients/$1.ovpn
echo -e "<cert>\n$(cat /etc/openvpn/easy-rsa/keys/$1.crt)\n</cert>" >> /etc/openvpn/clients/$1.ovpn
echo -e "<key>\n$(cat /etc/openvpn/easy-rsa/keys/$1.key)\n</key>" >> /etc/openvpn/clients/$1.ovpn
echo -e "<tls-auth>\n$(cat /etc/openvpn/easy-rsa/keys/ta.key)\n</tls-auth>" >> /etc/openvpn/clients/$1.ovpn


