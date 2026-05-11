#!/bin/bash

# Dirty Frag Vulnerability Checker
# Checks vulnerable kernel modules and mitigation status

echo "==============================================="
echo " Dirty Frag Vulnerability Checker"
echo "==============================================="
echo

# Hostname
echo "Hostname      : $(hostname)"
echo "Kernel Version: $(uname -r)"
echo

VULN=0

echo "Checking vulnerable modules..."
echo

for module in esp4 esp6 rxrpc
do
    if lsmod | grep -q "^${module}"; then
        echo "[WARNING] Module loaded: $module"
        VULN=1
    else
        echo "[OK] Module not loaded: $module"
    fi
done

echo
echo "Checking mitigation configuration..."
echo

if [ -f /etc/modprobe.d/dirtyfrag.conf ]; then
    echo "[OK] Mitigation file exists: /etc/modprobe.d/dirtyfrag.conf"

    for module in esp4 esp6 rxrpc
    do
        if grep -q "install $module /bin/false" /etc/modprobe.d/dirtyfrag.conf; then
            echo "[OK] $module blocked"
        else
            echo "[WARNING] $module NOT blocked properly"
            VULN=1
        fi
    done
else
    echo "[WARNING] Mitigation file NOT found"
    VULN=1
fi

echo
echo "Checking IPsec/VPN usage..."
echo

if systemctl is-active --quiet strongswan 2>/dev/null; then
    echo "[INFO] strongSwan service is ACTIVE"
fi

if systemctl is-active --quiet ipsec 2>/dev/null; then
    echo "[INFO] IPsec service is ACTIVE"
fi

if ip xfrm state 2>/dev/null | grep -q .; then
    echo "[INFO] IPsec xfrm states detected"
fi

echo
echo "==============================================="

if [ $VULN -eq 1 ]; then
    echo "[RESULT] ACTION REQUIRED"
    echo "Server may be vulnerable or mitigation incomplete."
else
    echo "[RESULT] Mitigation appears OK"
fi

echo "==============================================="