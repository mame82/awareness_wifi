#!/bin/bash
echo "Installing dependencies"
apt-get install -y dnsmasq mana-toolkit screen zipalign apksigner apktool

apt-get remove -y mitmproxy
apt-get install -y python3-dev python3-pip libffi-dev libssl-dev
pip3 install mitmproxy

echo "Next step will replace apktool.jar with snapshot of version 2.3.1 (on Kali Linux)"
echo "Press <CTRL> + <C> to prevent this, <Enter> to continue"
read

echo "Replacing apktool"
cp /usr/share/apktool/apktool.jar /usr/share/apktool/apktool.jar.bkp
cp apktool_2.3.1.jar /usr/share/apktool/apktool.jar
echo "New apktool version: "
apktool --version
