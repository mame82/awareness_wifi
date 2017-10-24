#!/bin/bash
echo "Installing dependencies"
apt-get install -y dnsmasq mana-toolkit screen

apt-get remove -y mitmproxy
apt-get install -y python3-dev python3-pip libffi-dev libssl-dev
pip3 install mitmproxy
