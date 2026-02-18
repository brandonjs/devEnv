#!/bin/bash

if [ "$(ps -ef | grep ninja-dev-sync | grep -v grep | grep -v vi | wc -l)" -le 14 ] 
then
    ninja-dev-sync 
    echo "NinjaDevSync Server Started"
else
    echo "NinjaDevSync Server Already Running"
fi
