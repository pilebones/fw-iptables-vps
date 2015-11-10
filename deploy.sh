#! /bin/sh

FW_SRC_PATH=$(pwd)/firewall.sh
SERVICE_NAME=firewall
FW_DST_PATH=/etc/init.d/$SERVICE_NAME
RUN_LEVEL_MANAGER=/sbin/chkconfig
CURRENT_USER=$(whoami)

if [ $CURRENT_USER = "root" ]; then
	if [ -f $FIREWALL_SCRIPT_PATH ]; then
		ln -s ${FW_SRC_PATH} ${FW_DST_PATH}
		chmod 700 ${FW_SRC_PATH}
		$RUN_LEVEL_MANAGER --level 06 $SERVICE_NAME off
		# Run level 2345 to override fail2ban rules (run level 3 is not enough)
		$RUN_LEVEL_MANAGER --level 2345 $SERVICE_NAME on
		echo "Firewall deployement done with success !"
	else
		echo "Script to deploy doesn't exist with path : ${FW_SRC_PATH}"
		exit 1
	fi
else
	echo "$0 must be run with root credentials"
	exit 1
fi
