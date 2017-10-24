#!/bin/bash
# Author: MaMe82


SCRIPTPATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd)"

source $SCRIPTPATH/setup.conf
	# kill remaining CP (only a single process)
	kill $(ps -aux | grep cp.py | grep -v -e grep | awk '{print $2}') 2> /dev/null
	# start python CP
	python cp.py -i $interface_hotspot -h $interface_hotspot_ip -p 8080 
