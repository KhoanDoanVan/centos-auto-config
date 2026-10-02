#!/usr/bin/env bash

set -uo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

source "${SCRIPT_DIR}/common.sh"

section() {
    printf '\n=== %s ===\n' "$1"
}

section "OPERATING SYSTEM"


if [[ -r /etc/os-release ]]; then
    source /etc/os-release
    printf 'Name:         %s\n' "${PRETTY_NAME:-unknown}"
fi

printf 'Hostname:     %s\n' "$(hostname)"
printf 'Kernel:       %s\n' "$(uname -r)"
printf 'Architecture: %s\n' "$(uname -m)"

section "CPU"

if command -v lscpu >/dev/null 2>&1; then
    lscpu |
        awk -F: '
            /^(Architecture|CPU\(s\)|Model name)/ {
                gsub(/^[[:space:]]+/, "", $2)
                printf "%-14s %s\n", $1 ":", $2
            }
        '
else
    warn "lscpu is not installed."
fi

section "MEMORY"

if command -v free >/dev/null 2>&1; then
    free -h
else
    warn "free is not available on this operating system."
fi

section "FILESYSTEMS"

df -h

section "NETWORK"

if command -v ip >/dev/null 2>&1; then
    ip -brief address
    ip route
else
    warn "The ip command is not available on this operating system."
fi

section "FAILED SYSTEMD UNITS"

if command -v systemctl >/dev/null 2>&1; then
    systemctl --failed --no-pager || true
else
    warn "systemd is not available on this operating system."
fi

