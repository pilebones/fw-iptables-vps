#! /bin/sh
FW_PATH=/etc/init.d/firewall
$FW_PATH stop && $FW_PATH start
