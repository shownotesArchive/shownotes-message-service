#!/bin/sh

# create sms.config if not exists
echo "Checking Config"
if [ ! -f "sms.config" ]; then
    cp sms.config.def sms.config
    $EDITOR sms.config
fi

# check directory in config file
dire=$(cat sms.config | grep directory | perl -n -e'm~directory\s+([\w+|/]+)~;print $1');

if [ ! -e "$dire" ]; then
    mkdir $dire;
    cd $dire;
    touch data.db #database name will be configureable in future versions
    cd ..;
fi

# scan and start
echo "Scanning for new Podcasts"
./scan.pl
echo "\nStarting Service"
./SMS.pl
