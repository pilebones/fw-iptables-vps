# fw-iptables-vps

Firewall configuration with Iptables for VPS (like OVH)

## Requirements
apt-get install chkconfig 

## Optionnal requirements 
apt-get install fail2ban

## How to install

su
cd /root/
git clone git@github.com:pilebones/fw-iptables-vps.git
mv fw-iptables-vps/ firewall
cd firewall
vim ip-ban.bd
vim ip-white-list.bd
./deploy.sh
./apply.sh

## Limitations

Currently, tested only on a VPS with Debian Jessie as OS
