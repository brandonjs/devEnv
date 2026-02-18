#!/bin/bash

killall ARDAgent
sudo rm -rf /var/db/RemoteManagement
sudo rm /Library/Preferences/com.apple.RemoteDesktop.plist
sudo rm -rf /Library/Application\ Support/Apple/Remote\ Desktop/
rm ~/Library/Preferences/com.apple.RemoteDesktop.plist
rm -rf ~/Library/Application\ Support/Remote\ Desktop/

/System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources

sudo ./kickstart -activate -configure -access -on -users brandons -privs -all -restart -agent -menu
