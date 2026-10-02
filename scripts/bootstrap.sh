#!/usr/bin/env bash


set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

source "${SCRIPT_DIR}/common.sh"
source "${SCRIPT_DIR}/packages.sh"
source "${SCRIPT_DIR}/services.sh"


on_error() {
    local exit_code=$?

    log ERROR \
        "Bootstrap failed at line ${BASH_LINENO[0]} (exit ${exit_code})."

    exit "$exit_code"
}

trap on_error ERR

require_root
require_command dnf
require_command rpm
require_command systemctl


is_centos_family ||
    die "This toolkit supports CentOS/RHEL-compatible systems only."


load_config


info "Starting CentOS bootstrap"

if is_true "${TOOLKIT_UPGRADE_SYSTEM:-false}"; then
    info "Refreshing metadata and upgrading installed packages"
    dnf upgrade --refresh -y
else
    info "System upgrade skipped by configuration"
fi


install_packages "${TOOLKIT_BASE_PACKAGES[@]}"

if is_true "${TOOLKIT_ENABLE_NGINX:-false}"; then
    install_packages nginx
fi


if [[ -n ${TOOLKIT_HOSTNAME:-} &&
      $(hostnamectl --static) != "$TOOLKIT_HOSTNAME" ]]
then
    info "Setting hostname to ${TOOLKIT_HOSTNAME}"
    hostnamectl set-hostname "$TOOLKIT_HOSTNAME"
else
    info "Hostname change not required"
fi


if [[ -n ${TOOLKIT_TIMEZONE:-} ]]; then
    current_timezone="$(
        timedatectl show --property=Timezone --value
    )"

    if [[ ${current_timezone} != "$TOOLKIT_TIMEZONE" ]]; then
        info "Setting timezone to ${TOOLKIT_TIMEZONE}"
        timedatectl set-timezone "$TOOLKIT_TIMEZONE"
    else
        info "Timezone already configured: ${TOOLKIT_TIMEZONE}"
    fi
fi


configure_services

info "Bootstrap completed successfully"
