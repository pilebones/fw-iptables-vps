# fw-iptables-vps

Firewall configuration with Iptables for VPS (like OVH)

## Requirements 
```bash
apt-get install chkconfig
```

## Optionnal requirements 
```bash
apt-get install fail2ban
```
## Security notice

Default allowed protocol :
- SSH (port 22)
- SMTP (port 25 : OUTPUT only)
- DNS (port 53)
- HTTP (port 80)
- HTTPS (port 443: OUTPUT only)
- GIT (port 9418)
- OVH for the supervision (port 6100/6200)

List of common attack this settings prevent :
- TCP-SYN/FIN/ACK scan
- TCP-XMAS scan
- Ping of Death
- Teardrop (fragmented UDP packets)
- ...

## How to install

```bash
su
cd /root/
git clone git@github.com:pilebones/fw-iptables-vps.git
mv fw-iptables-vps/ firewall
cd firewall
vim ip-ban.bd
vim ip-white-list.bd
./deploy.sh
./apply.sh
```

__Note :__ Don't miss to edit and update "ip-ban.bd" and "ip-white-list.bd" files by the future.

## Limitations

Currently, tested only on a VPS with Debian Jessie as OS
