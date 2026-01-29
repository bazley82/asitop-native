#!/bin/bash
echo "🔍 Checking powermetrics..."
which powermetrics
/usr/bin/powermetrics --version || echo "Failed to get version"

echo "🔍 Checking sudo status for powermetrics..."
sudo -n /usr/bin/powermetrics -i 1 -n 1 -f plist > /tmp/test_pm.plist 2>&1
if [ $? -eq 0 ]; then
    echo "✅ Passwordless sudo for powermetrics is WORKING."
    head -n 10 /tmp/test_pm.plist
else
    echo "❌ Passwordless sudo for powermetrics is NOT WORKING."
    cat /tmp/test_pm.plist
fi

echo "🔍 Checking sudoers file..."
if [ -f /etc/sudoers.d/asitop_native ]; then
    echo "✅ /etc/sudoers.d/asitop_native exists."
else
    echo "❌ /etc/sudoers.d/asitop_native MISSING."
fi
