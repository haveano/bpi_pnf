#!/bin/bash
wczoraj=$(date --date="yesterday" +%F)

cd /root/gielda3/
if [ -e /root/gielda3/d3.log ]
then
#	mv /root/gielda3/d3.log /root/gielda2/logs/d3.log.$(date +%F_%H:%M)
       mv /root/gielda3/d3.log /root/gielda3/logs/d3.log.$wczoraj
fi

