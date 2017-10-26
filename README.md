#author: MaMe82

WiFi security talk
==================
Extended hotspot scripts for wifi security talk
the scripts run on standard kali machine 

Only tested on Kali Linux

Tested WiFi NIC:	**ALFA AWUS036NHA (Atheros AR9271)**

Required
========

Kali with:
mana-toolkit + all the other tools installed by prepare.sh

Components
=============
- ships apktool 2.3.1 snapshot (2.3.0 shipped with kali couldn't rebuild current apps)
- prepare.sh: Install required packages (KALI only)
- setup.conf: Settings for the bash script (upstream adapter, Rogue AP adapter etc.)
- start_ap.sh: Brings up wireless AP in KARMA mode (creds to Sensepost)
- start_cp.sh: Starts a simple python based Captive Portal (experimental) and apllies needed iptables rules (start after AP is running)
- start_sslstrip.sh: Brings up SSLStrip+ (with HSTS bypass by domainn name substitution)
- start_ettercap.sh: Brings up ettercap, to show credentials from plain HTTP connections (in conjuction with SSLStrip)
- start_mitmproxy.sh: Brings mitmdump/mitmproxy (prebuild cert + private key included + downloadable from Captive Portal)
   - prepared setting to capture facebook logins and intercept HTTP requests for postings on facebook for mitmproxy
   - prepared script to transparently manipulate images of HTTP(S) traffic (flip top down, change to black and white and add a label)
   - mustn't be combined with SSLStrip in current setup !!!!!
- droidattack/listen.sh: Brings up a handler for Android payloads injected into app
- droidattack/appinject/createkey.sh: Creates keystore + privat/public key pair for APK signing (ships with key in release.keystore, password in scripts ;-))
- droidattack/appinject/app-release-unsigned.apk: !unsigned! template APP used for talk (does nothing but looking ugly)
- droidattack/appinject/sign-align.sh: script to zipalign and sign the given app (selfsigned cert from keystore key)
- droidattack/appinject/inject-payload.sh: !! injects the correct meterpreter payload for the handler build in listen.sh into the given (pre signed) app using apktool !!
- copies off the CA cert(used by mitmproxy) and the backdoored APK reside in var/www folder and get served by captive portal

- dns2proxy serves as default proxy for the AP and is especially needed to strip off the changes done by SSLStrip+. The code has been patched slightly to allow DNS name spoofing for HOST A entries without realworld counterpart (only existing domains are spoofable in former script) and an error answering A queries for the same host ore than once has been fixed.
- cp.py (the Captive Portal) isn't meant to e used in production and only serves the purpose of a security talk. Due to the underlying python implementation, HTTP requests are handled in sequential order which could stall the underlying HTTP server (client connects via TCP handshake but sends no request data --> server has to wait till timeout before other brequests are handled). This has been countered by adjusting the socket timeout of the HTTP server, which again leeds to problems for huge GET requests (app download). Timeout could only be adjusted in cp.py code, as no CLI option has been coded in.

