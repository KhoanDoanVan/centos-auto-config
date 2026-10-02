#!/usr/bin/env bash


TOOLKIT_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TOOLKIT_CONFIG="${TOOLKIT_CONFIG:-${TOOLKIT_ROOT}/config/server.conf}"


log() {
    local level="$1"
    shift

    printf '[%s] [%-5s] %s\n' \
        "$(date '+%Y-%m-%d %H:%M:%S')" \
        "$level" \
        "$*"
}


info() {
    log INFO "$@"
}

warn() {
    log WARN "$@" >&2
}


die() {
    log ERROR "$@" >&2
    exit 1
}


require_root() {
    [[ ${EUID} -eq 0 ]] ||
        die "Run this command with sudo or as root."
}


require_command() {
    command -v "$1" >/dev/null 2>&1 ||
        die "Required command not found: $1"
}

load_config() {
    [[ -r ${TOOLKIT_CONFIG} ]] ||
        die "Cannot read configuration: ${TOOLKIT_CONFIG}"

    source "${TOOLKIT_CONFIG}"
}


is_true() {
    case "${1,,}" in
        1|true|yes|on)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}


is_centos_family() {
    [[ -r /etc/os-release ]] || return 1

    source /etc/os-release

    [[ ${ID:-} == centos ||
        " ${ID_LIKE:-} " == *" rhel "* ]]
}

