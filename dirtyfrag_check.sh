#!/bin/bash

# ===================================================
# Dirty Frag Vulnerability Checker for Linux Servers
# ===================================================
#
# Usage:
# curl -s https://raw.githubusercontent.com/ajishcheeran/dirty-frag-mitigation/main/dirtyfrag_check.sh | bash
#
# ===================================================

clear

echo "==============================================="
echo " Dirty Frag Vulnerability Checker"
echo "==============================================="
echo

HOSTNAME=$(hostname)
KERNEL=$(uname -r)

echo "Hostname      : $HOSTNAME"
echo "Kernel Version: $KERNEL"
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

VPN_FOUND=0

if command -v systemctl >/dev/null 2>&1; then

    if systemctl is-active --quiet strongswan 2>/dev/null; then
        echo "[INFO] strongSwan service is ACTIVE"
        VPN_FOUND=1
    fi

    if systemctl is-active --quiet ipsec 2>/dev/null; then
        echo "[INFO] IPsec service is ACTIVE"
        VPN_FOUND=1
    fi
fi

if command -v ip >/dev/null 2>&1; then
    if ip xfrm state 2>/dev/null | grep -q .; then
        echo "[INFO] IPsec xfrm states detected"
        VPN_FOUND=1
    fi
fi

if [ $VPN_FOUND -eq 0 ]; then
    echo "[OK] No active IPsec/VPN detected"
fi

echo
echo "==============================================="

if [ $VULN -eq 1 ]; then
    echo "[RESULT] ACTION REQUIRED"
    echo "Server may be vulnerable or mitigation incomplete."
else
    echo "[RESULT] SERVER NOT VULNERABLE"
fi

echo "==============================================="
echo

# Optional mitigation suggestion

if [ $VULN -eq 1 ]; then

    echo "Recommended Mitigation:"
    echo

    echo "cat > /etc/modprobe.d/dirtyfrag.conf << EOF"
    echo "install esp4 /bin/false"
    echo "install esp6 /bin/false"
    echo "install rxrpc /bin/false"
    echo "EOF"

    echo
fi
