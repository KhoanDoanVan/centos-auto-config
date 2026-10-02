#!/usr/bin/env bash


set -Eeuo pipefail


SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"


source "${SCRIPT_DIR}/common.sh"


install_packages() {
    local -a missing=()
    local package

    for package in "$@"; do
        if rpm -q "$package" >/dev/null 2>&1; then
            info "Package already installed: ${package}"
        else
            missing+=("$package")
        fi
    done

    if ((${#missing[@]} == 0)); then
        info "All requested packages are already installed."
        return 0
    fi

    info "Installing packages: ${missing[*]}"
    dnf install -y "${missing[@]}"
}


if [[ ${BASH_SOURCE[0]} == "$0" ]]; then
    require_root
    require_command rpm
    require_command dnf

    (($# > 0)) ||
        die "Usage: $0 PACKAGE [PACKAGE ...]"

    install_packages "$@"
fi


set -Eeuo pipefail
