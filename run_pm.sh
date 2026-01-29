#!/bin/bash
# run_pm.sh
# This script ensures powermetrics output is correctly captured and formatted
sudo -n /usr/bin/powermetrics -i 1000 -n -1 -b 1 -f plist
