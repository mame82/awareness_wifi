#!/bin/bash
THISPATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd)"
source $THISPATH/setup.conf 

ettercap -p -u -T -q -i $interface_hotspot

