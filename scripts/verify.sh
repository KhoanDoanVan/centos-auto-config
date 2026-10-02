#!/usr/bin/env bash


set -uo pipefail


SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"


source "${SCRIPT_DIR}/common.sh"

PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0


pass() {
    printf '[PASS] %s\n' "$1"
    ((PASS_COUNT += 1))
}

fail() {
    printf '[FAIL] %s\n' "$1"
    ((FAIL_COUNT += 1))
}

notice() {
    printf '[WARN] %s\n' "$1"
    ((WARN_COUNT += 1))
}

check_service() {
    local service="$1"

    if systemctl is-active --quiet "$service"; then
        pass "${service} is active"
    else
        fail "${service} is not active"
    fi

    if systemctl is-enabled --quiet "$service"; then
        pass "${service} is enabled at boot"
    else
        fail "${service} is not enabled at boot"
    fi
}

printf 'CentOS Auto Configuration Toolkit - verification\n\n'

if is_centos_family; then
    pass "CentOS/RHEL-compatible operating system detected"
else
    fail "Unsupported operating system"
fi

if ip route | grep -q '^default '; then
    pass "Default network route exists"
else
    fail "Default network route is missing"
fi

if getent hosts centos.org >/dev/null 2>&1; then
    pass "DNS resolution works"
else
    fail "DNS resolution failed"
fi

check_service sshd.service
check_service firewalld.service

if firewall-cmd --query-service=ssh >/dev/null 2>&1; then
    pass "SSH is allowed in the active firewall zone"
else
    fail "SSH is not allowed in the active firewall zone"
fi

if [[ $(getenforce 2>/dev/null) == Enforcing ]]; then
    pass "SELinux is enforcing"
else
    fail "SELinux is not enforcing"
fi

if systemctl list-unit-files nginx.service \
    --no-legend 2>/dev/null |
    grep -q '^nginx.service'
then
    if systemctl is-active --quiet nginx.service; then
        pass "Optional nginx service is active"
    else
        notice "nginx is installed but not active"
    fi
fi

while read -r filesystem percent mountpoint; do
    usage=${percent%%%}

    if ((usage >= 90)); then
        fail \
            "Filesystem ${filesystem} at ${mountpoint} is ${percent} full"
    elif ((usage >= 80)); then
        notice \
            "Filesystem ${filesystem} at ${mountpoint} is ${percent} full"
    fi
done < <(
    df -P -x tmpfs -x devtmpfs |
        awk 'NR > 1 {print $1, $5, $6}'
)

printf '\nSummary: %d passed, %d warnings, %d failed\n' \
    "$PASS_COUNT" \
    "$WARN_COUNT" \
    "$FAIL_COUNT"

if ((FAIL_COUNT > 0)); then
    exit 1
fi