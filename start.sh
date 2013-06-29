#!/bin/sh

if [ ! -f "sms.config" ]; then
    cp sms.config.def sms.config
    $EDITOR sms.config
fi

./SMS.pl
