#!/bin/bash

#On commence par activer la redirection IP

sudo sysctl -w net.ipv4.ip_forward=1

#On accepte les paquets arrivants sur eth0

sudo iptables -A FORWARD -i eth0 -j ACCEPT
sudo iptables -A FORWARD -o eth0 -j ACCEPT

#Ensuite on va rediriger ces paquets sur wlan0 

sudo iptables -t nat -A POSTROUTING -o wlan0 -j MASQUERADE
