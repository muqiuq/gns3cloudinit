#!/bin/bash

echo "Disable cloudinit netplan"

echo "network: {config: disabled}" > /etc/cloud/cloud.cfg.d/99-disable-network-config.cfg

ETH=`ip link | awk -F: '$0 !~ "lo|vir|wl|tap|br|^[^0-9]"{print $2;getline}'`

ETH=`echo $ETH | sed 's/ *$//g'`

echo "Adding ifupdown configuration"

cat <<EOFMOTD > /etc/network/interfaces.d/default
auto $ETH
iface $ETH inet dhcp

auto br0
iface br0 inet static
address 192.168.23.1
netmask 255.255.255.0
pre-up brctl addbr br0

EOFMOTD


echo "Disable iptables for bridge"
# sysctl -w net.bridge.bridge-nf-call-iptables=0
# This is not really working
cat <<EOFCTL > /etc/sysctl.d/10-no-bridge-nf-call.conf
# So that Client To Client Communication works
net.bridge.bridge-nf-call-iptables=0

EOFCTL

# This doesn't really does something unless you enable ufw
echo "...fix ufw too"

cat <<EOFUFW >> /etc/ufw/sysctl.conf

net/bridge/bridge-nf-call-ip6tables = 0
net/bridge/bridge-nf-call-iptables = 0
net/bridge/bridge-nf-call-arptables = 0

EOFUFW

# This works in combination with the sysctl-reload.service
echo "...add it to sysctl.conf"

cat <<EOFSYS >> /etc/sysctl.conf
# So that Client To Client Communication works
net.bridge.bridge-nf-call-iptables=0
net.bridge.bridge-nf-call-ip6tables=0

EOFSYS

echo "...add service to reload sysctl after boot"

# Apparently we have to reload sysctl because reasons
cat <<EOFCTL > /opt/sysctl-reload.service
[Unit]
Description=sysctl reload
Requires=multi-user.target
After=multi-user.target

[Service]
Type=oneshot
ExecStart=/usr/sbin/sysctl -p

[Install]
WantedBy=multi-user.target

EOFCTL

systemctl enable /opt/sysctl-reload.service

echo "Disable netplan"
rm -rf /etc/netplan/*

HOSTNAME=`hostname`

cat <<EOFDHCP > /etc/dhcp/dhcpd.conf
option domain-name "$HOSTNAME.local";

default-lease-time 600;
max-lease-time 7200;

subnet 192.168.23.0 netmask 255.255.255.0 {
 range 192.168.23.129 192.168.23.200;
 option domain-name-servers 8.8.8.8;
 option domain-name "$HOSTNAME.local";
}
EOFDHCP

sed -i 's/INTERFACESv4=""/INTERFACESv4="br0"/g' /etc/default/isc-dhcp-server

echo "Done setting up dhcpd"

MY_IP_ADDR=`ip addr show $ETH | grep -o "inet [0-9]*\.[0-9]*\.[0-9]*\.[0-9]*" | grep -o "[0-9]*\.[0-9]*\.[0-9]*\.[0-9]*"`

MY_IP_ADDR=(${MY_IP_ADDR[@]})

echo "My IP is $MY_IP_ADDR"


UUID=$(uuid)

echo "Update motd"

cat <<EOFMOTD > /etc/update-motd.d/70-gns3lab
#!/bin/sh
echo "GNS3 Lab Instance by Philipp Albrecht <philipp@uisa.ch>"
echo "_______________________________________________________________________________________________"
echo ""
EOFMOTD
chmod 755 /etc/update-motd.d/70-gns3lab


mkdir -p /etc/openvpn/

echo "Create keys"

[ -f /etc/openvpn/dh.pem ] || openssl dhparam -out /etc/openvpn/dh.pem 2048
[ -f /etc/openvpn/key.pem ] || openssl genrsa -out /etc/openvpn/key.pem 2048
chmod 600 /etc/openvpn/key.pem
[ -f /etc/openvpn/csr.pem ] || openssl req -new -key /etc/openvpn/key.pem -out /etc/openvpn/csr.pem -subj /CN=OpenVPN/
[ -f /etc/openvpn/cert.pem ] || openssl x509 -req -in /etc/openvpn/csr.pem -out /etc/openvpn/cert.pem -signkey /etc/openvpn/key.pem -days 24855

echo "Create client configuration"
cat <<EOFCLIENT > /home/philipp/$HOSTNAME.ovpn
client
nobind
comp-lzo
dev tap
<key>
`cat /etc/openvpn/key.pem`
</key>
<cert>
`cat /etc/openvpn/cert.pem`
</cert>
<ca>
`cat /etc/openvpn/cert.pem`
</ca>
<connection>
remote $MY_IP_ADDR 1194 tcp
</connection>
EOFCLIENT

cat <<EOFUDP > /etc/openvpn/server.conf
server-bridge
verb 3
duplicate-cn
comp-lzo
key key.pem
ca cert.pem
cert cert.pem
dh dh.pem
keepalive 10 60
persist-key
persist-tun
proto tcp
port 1194
dev tap1
status openvpn-status.log
log-append /var/log/openvpn.log
up "/bin/bash /etc/openvpn/bridge-start"
down "/bin/bash /etc/openvpn/bridge-stop"
EOFUDP

cat <<EOFBS > /etc/openvpn/bridge-start
#!/bin/bash
br="br0"
tap=\$1

for t in \$tap; do
    brctl addif \$br \$t
done

for t in \$tap; do
    ifconfig \$t 0.0.0.0 promisc up
done

EOFBS

cat <<EOFBS > /etc/openvpn/bridge-stop
#!/bin/bash
br="br0"
tap=\$1


EOFBS


echo "Restart OpenVPN"

set +e
systemctl daemon-reload

systemctl stop openvpn
systemctl start openvpn

echo "Notifying success"

curl -F "ovpn=@/home/user/$HOSTNAME.ovpn" -F "ip=$MY_IP_ADDR" -F "name=$HOSTNAME" http://MASTERNODE/up.php
