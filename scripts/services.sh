#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

source "${SCRIPT_DIR}/common.sh"

enable_service() {
    local service="$1"

    info "Enabling and starting ${service}"

    systemctl enable --now "$service"

    systemctl is-active --quiet "$service" ||
        die "Service is not active: ${service}"
}

allow_firewall_service() {
    local service="$1"

    if firewall-cmd \
        --permanent \
        --query-service="$service" >/dev/null 2>&1
    then
        info "Firewall service already allowed: ${service}"
    else
        info "Allowing firewall service: ${service}"

        firewall-cmd \
            --permanent \
            --add-service="$service"

        FIREWALL_CHANGED=true
    fi
}

configure_services() {
    FIREWALL_CHANGED=false

    enable_service sshd.service
    enable_service firewalld.service

    allow_firewall_service ssh

    if is_true "${TOOLKIT_ENABLE_NGINX:-false}"; then
        enable_service nginx.service
        allow_firewall_service http
    fi

    if [[ ${FIREWALL_CHANGED} == true ]]; then
        info "Reloading firewalld"
        firewall-cmd --reload
    fi
}


if [[ ${BASH_SOURCE[0]} == "$0" ]]; then
    require_root
    load_config
    configure_services
fi


