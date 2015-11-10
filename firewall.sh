#! /bin/bash

### BEGIN INIT INFO
# Provides: Firewall for personnal server
# Required-Start:
# Required-Stop:
# Default-Start: 3
# Default-Stop: 0 6
# Short-Description: Apply secure rules for firewall
# Description: Apply secure rules for firewall
### END INIT INFO

IPT=/sbin/iptables
INTERFACES="venet0"

# sysctl location.  If set, it will use sysctl to adjust the kernel parameters.
# If this is set to the empty string (or is unset), the use of sysctl is disabled.
SYSCTL="/sbin/sysctl -w"

case "$1" in
start)

# This enables SYN flood protection.
# The SYN cookies activation allows your system to accept an unlimited
# number of TCP connections while still trying to give reasonable
# service during a denial of service attack.
if [ -z "$SYSCTL" ]; then 
    echo "1" > /proc/sys/net/ipv4/tcp_syncookies
else
    $SYSCTL net.ipv4.tcp_syncookies="1"
fi

# Simplest method of disabling ping response
if [ -z "$SYSCTL" ]; then 
	echo "1" > /proc/sys/net/ipv4/icmp_echo_ignore_all
else
    $SYSCTL net.ipv4.icmp_echo_ignore_all="1"
fi

# This kernel parameter instructs the kernel to ignore all ICMP
# echo requests sent to the broadcast address.  This prevents
# a number of smurfs and similar DoS nasty attacks.
if [ -z "$SYSCTL" ]; then
	echo "1" > /proc/sys/net/ipv4/icmp_echo_ignore_broadcasts
else
	$SYSCTL net.ipv4.icmp_echo_ignore_broadcasts="1"
fi

# This option can disable ICMP redirects.  ICMP redirects
# are generally considered a security risk and shouldn't be
# needed by most systems using this generator.
if [ -z "$SYSCTL" ]; then
	echo "0" > /proc/sys/net/ipv4/conf/all/accept_redirects
else
	$SYSCTL net.ipv4.conf.all.accept_redirects="0"
fi

# However, we'll ensure the secure_redirects option is on instead.
# This option accepts only from gateways in the default gateways list.
if [ -z "$SYSCTL" ]; then
    echo "1" > /proc/sys/net/ipv4/conf/all/secure_redirects
else
    $SYSCTL net.ipv4.conf.all.secure_redirects="1"
fi

# This option logs packets from impossible addresses.
if [ -z "$SYSCTL" ]; then
	echo "1" > /proc/sys/net/ipv4/conf/all/log_martians
else
	$SYSCTL net.ipv4.conf.all.log_martians="1"
fi

# Flush I/O firewall table
echo "Flush previous iptables rules set..."
$IPT -F INPUT
$IPT -F OUTPUT
$IPT -F FORWARD
# Flush PRE/POST ROUTINGS
for i in $( $IPT -t nat --line-numbers -L | grep ^[0-9] | awk '{ print $1 }' | tac ); do 
	$IPT -t nat -D PREROUTING $i
	$IPT -t nat -D POSTROUTING $i
done

# Don't break related / established connection
echo "Add rules for related/established connections..."
$IPT -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
$IPT -A OUTPUT -m state --state RELATED,ESTABLISHED -j ACCEPT

# Allowed loopback
echo "Add rules for loopback..."
$IPT -t filter -A INPUT -i lo -j ACCEPT
$IPT -t filter -A OUTPUT -o lo -j ACCEPT

# ICMP (Ping)
echo "Add rules for ICMP..."
# $IPT -A INPUT -p icmp --icmp-type echo-request -j DROP
$IPT -t filter -A INPUT -p icmp -j ACCEPT
$IPT -t filter -A OUTPUT -p icmp -j ACCEPT

# BAN some referenced IPs
echo "Add rules for BAN referenced IPs"
BAN_DB=/root/firewall/ip-ban.db
IPS=$(grep -Ev "^#" $BAN_DB)
for ip in $IPS; do
	$IPT -A INPUT -s $ip -j DROP
	$IPT -A OUTPUT -d $ip -j DROP
done

# White-list referenced IPs
echo "Add rules for White-list referenced IPs"
WHITELIST_DB=/root/firewall/ip-white-list.db
IPS=$(grep -Ev "^#" $WHITELIST_DB)
for ip in $IPS; do
	$IPT -A INPUT -s $ip -j ACCEPT
	$IPT -A OUTPUT -d $ip -j ACCEPT
done

for INTERFACE in $INTERFACES; do
	# SSH (I/O)
	echo "Add rules for SSH (iface: ${INTERFACE})..."
	$IPT -A INPUT -i $INTERFACE -p tcp --dport 22 -j ACCEPT
	$IPT -A OUTPUT -o $INTERFACE -p tcp --dport 22 -j ACCEPT
	$IPT -A FORWARD -o $INTERFACE -p tcp --dport 22 -j ACCEPT
	
	# SMTP (Ouput only)
	echo "Add rules for SMTP (iface: ${INTERFACE})..."
	$IPT -A OUTPUT -o $INTERFACE -p tcp --dport 25 -j ACCEPT
	
	# DNS (Ouput only)
	echo "Add rules for DNS (iface: ${INTERFACE})..."
	$IPT -A OUTPUT -o $INTERFACE -p tcp --dport 53 -j ACCEPT
	$IPT -A OUTPUT -o $INTERFACE -p udp --dport 53 -j ACCEPT

	# HTTP (Ouput only)
	echo "Add rules for HTTP (iface: ${INTERFACE})..."
	$IPT -A INPUT -i $INTERFACE -p tcp --dport 80 -j ACCEPT
	$IPT -A OUTPUT -o $INTERFACE -p tcp --dport 80 -j ACCEPT
	$IPT -A OUTPUT -o $INTERFACE -p tcp --dport 443 -j ACCEPT

	# GIT (Ouput only) (ie: http://git-scm.com/book/en/v2/Git-on-the-Server-The-Protocols#The-Git-Protocol)
	echo "Add rules for GIT (iface: ${INTERFACE})..."
	$IPT -A INPUT -i $INTERFACE -p tcp --dport 9418 -j ACCEPT
	$IPT -A OUTPUT -o $INTERFACE -p tcp --dport 9418 -j ACCEPT
	
	# OVH (ie: http://guide.ovh.com/FireWall)
	echo "Add rules for OVH (iface: ${INTERFACE})..."
	$IPT -A INPUT -i $INTERFACE -p udp --dport 6100 -j ACCEPT
	$IPT -A OUTPUT -o $INTERFACE -p udp --dport 6100 -j ACCEPT
	$IPT -A INPUT -i $INTERFACE -p udp --dport 6200 -j ACCEPT
	$IPT -A OUTPUT -o $INTERFACE -p udp --dport 6200 -j ACCEPT
done

#
# Limit port scanning
#

# echo "Add rules to limit port scanning..."
# $IPT -A port-scan -p tcp --tcp-flags SYN,ACK,FIN,RST RST -m limit --limit 1/s -j RETURN
# $IPT -A port-scan -j DROP

#
# Limit SYN flooding
#

# echo "Add rules to limit SYN flooding..."
# $IPT -A specific-rule-set -p tcp --syn -j syn-flood
# $IPT -A specific-rule-set -p tcp --tcp-flags SYN,ACK,FIN,RST RST -j port-scan

#
# Protect against common attacks
#

echo "Block TCP-SYN scan attempts (only SYN bit packets)"
$IPT -A INPUT -m conntrack --ctstate NEW -p tcp --tcp-flags SYN,RST,ACK,FIN,URG,PSH SYN -j DROP

echo "Block TCP-FIN scan attempts (only FIN bit packets)"
$IPT -A INPUT -m conntrack --ctstate NEW -p tcp --tcp-flags SYN,RST,ACK,FIN,URG,PSH FIN -j DROP

echo "Block TCP-ACK scan attempts (only ACK bit packets)"
$IPT -A INPUT -m conntrack --ctstate NEW -p tcp --tcp-flags SYN,RST,ACK,FIN,URG,PSH ACK -j DROP

# echo "Block TCP-NULL scan attempts (packets without flag)"
# $IPT -A INPUT -m conntrack --ctstate INVALID -p tcp --tcp-flags ! SYN,RST,ACK,FIN,URG,PSH SYN,RST,ACK,FIN,URG,PSH -j DROP

echo "Block "Christmas Tree" TCP-XMAS scan attempts (packets with FIN, URG, PSH bits)"
$IPT -A INPUT -m conntrack --ctstate NEW -p tcp --tcp-flags SYN,RST,ACK,FIN,URG,PSH FIN,URG,PSH -j DROP

echo "Block DOS - Ping of Death"
$IPT -A INPUT -p ICMP --icmp-type echo-request -m length --length 60:65535 -j ACCEPT

echo "Block DOS - Teardrop (fragmented UDP packets)"
$IPT -A INPUT -p UDP -f -j DROP

# echo "Block DDOS - SYN-flood"
# $IPT -A INPUT -p TCP --syn -m iplimit --iplimit-above 9 -j DROP

# echo "Block DDOS - Smurf"
# $IPT -A INPUT -m pkttype --pkt-type broadcast -j DROP

# $IPT -A INPUT -p ICMP --icmp-type echo-request -m pkttype --pkttype broadcast -j DROP
# $IPT -A INPUT -p ICMP --icmp-type echo-request -m limit --limit 3/s -j ACCEPT

# echo "Block DDOS - Connection-flood"
# $IPT -A INPUT -p TCP --syn -m iplimit --iplimit-above 3 -j DROP

echo "Block DDOS - Fraggle"
$IPT -A INPUT -p UDP -m pkttype --pkt-type broadcast -j DROP
$IPT -A INPUT -p UDP -m limit --limit 3/s -j ACCEPT

for INTERFACE in $INTERFACES; do
	# Reject everything else
	echo "Add reject rules (iface: ${INTERFACE})..."
	$IPT -A INPUT -i $INTERFACE -j REJECT
	$IPT -A OUTPUT -o $INTERFACE -j REJECT
	$IPT -A FORWARD -o $INTERFACE -j REJECT
done

echo "Firewall rules set successfully !"

exit 0
;;

stop)

$IPT -F INPUT
$IPT -F OUTPUT
$IPT -F FORWARD
# $IPT -F port-scan
# $IPT -F specific-rule-set

exit 0
;;
*)
echo "Usage: /etc/init.d/firewall {start|stop}"
exit 1
;;
esac
