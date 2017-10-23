#!/bin/bash
if [ $# -lt 1 ]    # lt = lower then
   then
   echo "Syntax ..."
   echo "\$ $0 hostapd_log_file"
   exit 1
fi

#NEW_FILENAME=$(echo $1 | sed 's!\.[a-zA-Z0-9]*!_clear.log!g')
#echo $NEW_FILENAME

SRC_PATH=${1%/*}
SRC_FILE=${1##*/}
NEW_FILENAME=$SRC_PATH"/wlan_list_$SRC_FILE"

#echo $NEW_FILENAME
#cat $1 | grep "Directed probe request for foreign SSID" | sort -u | cut -c48- | sed -e 's! ([0-9]*) for STA !\t\t\[!g;s!$!\]!' | tee $NEW_FILENAME
cat $1 | grep "Directed probe request for foreign SSID" | sort -u | cut -c48- | tee $NEW_FILENAME

