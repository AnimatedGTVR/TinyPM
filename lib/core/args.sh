#!/usr/bin/env bash

dispatch_multicall() {
    case "$prog_name" in
        ainstall) echo "install auto" ;;
        search) echo "search auto" ;;
        term) echo "remove auto" ;;
        start) echo "run auto" ;;
        supdate) echo "update auto" ;;
        *) echo "help auto" ;;
    esac
}

parse_action_args() {
    local default_provider="$1"
    shift

    provider="$default_provider"
    package=""

    case "$action" in
        list|managed|apps|app|update|doctor|help|version|-v|--version)
            if [[ $# -gt 0 ]] && provider="$(provider_from_flag "$1")"; then
                shift
            fi
            ;;
        *)
            if [[ $# -gt 0 ]] && provider="$(provider_from_flag "$1")"; then
                shift
            fi

            if [[ $# -gt 0 ]]; then
                package="$1"
                shift
            fi

            if [[ $# -gt 0 ]] && provider="$(provider_from_flag "$1")"; then
                shift
            fi
            ;;
    esac

    [[ $# -eq 0 ]] || die "too many arguments"
}

init_cli_context() {
    if [[ "$prog_name" == "tiny" || "$prog_name" == "tinypm" ]]; then
        action="${1:-help}"
        shift || true
        parse_action_args "auto" "$@"
        return
    fi

    read -r action provider < <(dispatch_multicall)
    parse_action_args "$provider" "$@"
}
