#!/bin/bash
wczoraj=$(date --date="yesterday" +%F)

cd /root/bpi/
if [ -e /root/bpi/bpi.log ]
then
       mv /root/bpi/bpi.log /root/bpi/logs/bpi.log.$wczoraj
fi

