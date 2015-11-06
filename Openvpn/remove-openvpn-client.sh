#!/bin/bash 
# Samuel Aubertin
if [[ -z "$1" ]]
then
	echo "First parameter (username) missing..."
	exit
fi

echo "Removing $1 to OpenVPN clients."
echo "Samuel Aubertin - 2014"
echo "Enter to continue, Ctrl+C to leave"
read

# Lets go to the easyy-rsa dir and get server config
cd /etc/openvpn/easy-rsa 
source ./vars

# Now lets revoke the SSL key of our client 
./revoke-full $1
grep -e '^R' keys/index.txt | grep $1 
#openssl crl -in keys/crl.pem -text
cp -f keys/crl.pem /etc/openvpn/crl.pem
chown nobody /etc/openvpn/crl.pem 
chmod 700 /etc/openvpn/crl.pem 

grep -q -F 'crl-verify /etc/openvpn/crl.pem' /etc/openvpn/server.conf || echo 'crl-verify /etc/openvpn/crl.pem' >> /etc/openvpn/server.conf && service openvpn restart
