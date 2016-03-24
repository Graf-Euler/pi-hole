#!/usr/bin/env bash
# Pi-hole: A black hole for Internet advertisements
# (c) 2015, 2016 by Jacob Salmela
# Network-wide ad blocking via your Raspberry Pi
# http://pi-hole.net
# Generates pihole_debug.log in /var/log/ to be used for troubleshooting.
#
# Pi-hole is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 2 of the License, or
# (at your option) any later version.

# Nate Brandeburg
# nate@ubiquisoft.com
# 3/24/2016

######## GLOBAL VARS ########
DEBUG_LOG="/var/log/pihole_debug.log"
DNSMASQFILE="/etc/dnsmasq.conf"
PIHOLECONFFILE="/etc/dnsmasq.d/01-pihole.conf"
LIGHTTPDFILE="/etc/lighttpd/lighttpd.conf"
GRAVITYFILE="/etc/pihole/gravity.list"
HOSTSFILE="/etc/hosts"
WHITELISTFILE="/etc/pihole/whitelist.txt"
BLACKLISTFILE="/etc/pihole/blacklist.txt"
ADLISTSFILE="/etc/pihole/adlists.list"
PIHOLELOG="/var/log/pihole.log"


######## FIRST CHECK ########
# Must be root to debug
if [[ $EUID -eq 0 ]];then
	echo "You are root... Beginning debug!"
else
	echo "sudo will be used for debugging."
	# Check if sudo is actually installed
	if [[ $(dpkg-query -s sudo) ]];then
		export SUDO="sudo"
	else
		echo "Please install sudo or run this as root."
		exit 1
	fi
fi

# Ensure the file exists, create if not, clear if exists.
if [ ! -f "$DEBUG_LOG" ] 
then
	$SUDO touch $DEBUG_LOG
	$SUDO chmod 644 $DEBUG_LOG
	$SUDO chown "$USER":root $DEBUG_LOG
else 
	truncate -s 0 $DEBUG_LOG
fi

### Private functions exist here ###
function compareWhitelist {
	echo "#######################################" >> $DEBUG_LOG
	echo "######## Whitelist Comparison #########" >> $DEBUG_LOG
	echo "#######################################" >> $DEBUG_LOG
	while read -r line; do
		grep -w ".* $line$" "$GRAVITYFILE" >> $DEBUG_LOG
	done < "$WHITELISTFILE"
	echo >> $DEBUG_LOG
}

function compareBlacklist {
	echo "#######################################" >> $DEBUG_LOG
	echo "######## Blacklist Comparison #########" >> $DEBUG_LOG
	echo "#######################################" >> $DEBUG_LOG
	while read -r line; do
		grep -w ".* $line$" "$GRAVITYFILE" >> $DEBUG_LOG
	done < "$BLACKLISTFILE"
	echo >> $DEBUG_LOG
}

function testNslookup {
	# TODO: This will pull a non-matched entry from gravity.list to compare with the nslookup against Google's NS.
	echo >> $DEBUG_LOG
}

### Check Pi internet connections ###
# Log the IP addresses of this Pi
IPADDR=$(ifconfig | perl -nle 's/dr:(\S+)/print $1/e')
echo "Writing local IPs to debug log"
echo "IP Addresses of this Pi:" >> $DEBUG_LOG
echo "$IPADDR" >> $DEBUG_LOG
echo >> $DEBUG_LOG

# Check if we can connect to the local gateway
GATEWAY_CHECK=$(ping -q -w 1 -c 1 "$(ip r | grep default | cut -d ' ' -f 3)" > /dev/null && echo ok || echo error)
echo "Gateway check:" >> $DEBUG_LOG
echo "$GATEWAY_CHECK" >> $DEBUG_LOG
echo >> $DEBUG_LOG

echo "Writing dnsmasq.conf to debug log..."
echo "#######################################" >> $DEBUG_LOG
echo "############### Dnsmasq ###############" >> $DEBUG_LOG
echo "#######################################" >> $DEBUG_LOG
if [ -e "$DNSMASQFILE" ]
then
	#cat $DNSMASQFILE >> $DEBUG_LOG
	while read -r line; do
		[[ "$line" =~ ^#.*$ ]] && continue
		echo "$line" >> $DEBUG_LOG
	done < "$DNSMASQFILE"
	echo >> $DEBUG_LOG
else
	echo "No dnsmasq.conf file found!" >> $DEBUG_LOG
	echo "No dnsmasq.conf file found!"
fi

echo "Writing 01-pihole.conf to debug log..."
echo "#######################################" >> $DEBUG_LOG
echo "########### 01-pihole.conf ############" >> $DEBUG_LOG
echo "#######################################" >> $DEBUG_LOG
if [ -e "$PIHOLECONFFILE" ]
then
	#cat "$PIHOLECONFFILE" >> $DEBUG_LOG
	while read -r line; do
		[[ "$line" =~ ^#.*$ ]] && continue
		echo "$line" >> $DEBUG_LOG
	done < "$PIHOLECONFFILE"
	echo >> $DEBUG_LOG
else
	echo "No 01-pihole.conf file found!" >> $DEBUG_LOG
	echo "No 01-pihole.conf file found"
fi

echo "Writing lighttpd.conf to debug log..."
echo "#######################################" >> $DEBUG_LOG
echo "############ lighttpd.conf ############" >> $DEBUG_LOG
echo "#######################################" >> $DEBUG_LOG
if [ -e "$LIGHTTPDFILE" ]
then
	#cat "$PIHOLECONFFILE" >> $DEBUG_LOG
	while read -r line; do
		[[ "$line" =~ ^#.*$ ]] && continue
		echo "$line" >> $DEBUG_LOG
	done < "$LIGHTTPDFILE"
	echo >> $DEBUG_LOG
else
	echo "No lighttpd.conf file found!" >> $DEBUG_LOG
	echo "No lighttpd.conf file found"
fi

echo "Writing size of gravity.list to debug log..."
echo "#######################################" >> $DEBUG_LOG
echo "############ gravity.list #############" >> $DEBUG_LOG
echo "#######################################" >> $DEBUG_LOG
if [ -e "$GRAVITYFILE" ]
then
	wc -l "$GRAVITYFILE" >> $DEBUG_LOG
	echo >> $DEBUG_LOG
else
	echo "No gravity.list file found!" >> $DEBUG_LOG
	echo "No gravity.list file found"
fi

# Write the hostname output to compare against entries in /etc/hosts, which is logged next
echo "Hostname of this pihole is: " >> $DEBUG_LOG
hostname >> $DEBUG_LOG
echo >> $DEBUG_LOG

echo "Writing hosts file to debug log..."
echo "#######################################" >> $DEBUG_LOG
echo "################ Hosts ################" >> $DEBUG_LOG
echo "#######################################" >> $DEBUG_LOG
if [ -e "$HOSTSFILE" ]
then
	cat "$HOSTSFILE" >> $DEBUG_LOG
	echo >> $DEBUG_LOG
else
	echo "No hosts file found!" >> $DEBUG_LOG
	echo "No hosts file found!"
fi

### PiHole application specific logging ###
# Write Pi-Hole logs to debug log
echo "Writing whitelist to debug log..."
echo "#######################################" >> $DEBUG_LOG
echo "############## Whitelist ##############" >> $DEBUG_LOG
echo "#######################################" >> $DEBUG_LOG
if [ -e "$WHITELISTFILE" ]
then
	cat "$WHITELISTFILE" >> $DEBUG_LOG
	echo >> $DEBUG_LOG
else
	echo "No whitelist.txt file found!" >> $DEBUG_LOG
	echo "No whitelist.txt file found!"
fi

echo "Writing blacklist to debug log..."
echo "#######################################" >> $DEBUG_LOG
echo "############## Blacklist ##############" >> $DEBUG_LOG
echo "#######################################" >> $DEBUG_LOG
if [ -e "$BLACKLISTFILE" ]
then
	cat "$BLACKLISTFILE" >> $DEBUG_LOG
	echo >> $DEBUG_LOG
else
	echo "No blacklist.txt file found!" >> $DEBUG_LOG
	echo "No blacklist.txt file found!"
fi

echo "Writing adlists.list to debug log..."
echo "#######################################" >> $DEBUG_LOG
echo "############ adlists.list #############" >> $DEBUG_LOG
echo "#######################################" >> $DEBUG_LOG
if [ -e "$ADLISTSFILE" ]
then
	cat "$ADLISTSFILE" >> $DEBUG_LOG
	echo >> $DEBUG_LOG
else
	echo "No adlists.list file found!" >> $DEBUG_LOG
	echo "No adlists.list file found!"
fi


# Continuously append the pihole.log file to the pihole_debug.log file
function dumpPiHoleLog {
	trap '{ echo -e "\nFinishing debug write from interrupt... Quitting!" ; exit 1; }' INT
	echo -e "Writing current pihole traffic to debug log...\nTry loading any/all sites that you are having trouble with now... (Press ctrl+C to finish)"
	echo "#######################################" >> $DEBUG_LOG
	echo "############# pihole.log ##############" >> $DEBUG_LOG
	echo "#######################################" >> $DEBUG_LOG
	if [ -e "$PIHOLELOG" ]
	then
		while true; do
			tail -f "$PIHOLELOG" >> $DEBUG_LOG
			echo >> $DEBUG_LOG
		done
	else
		echo "No pihole.log file found!" >> $DEBUG_LOG
		echo "No pihole.log file found!"
	fi
}

# Anything to be done after capturing of pihole.log terminates
function finalWork {
	echo "Finshed debugging!"
}
trap finalWork EXIT

### Method calls for additional logging ###
dumpPiHoleLog
