#!/usr/bin/env bash
# shellcheck disable=SC2034,SC2154

doctor_fix=0
repo_name=""

dispatch_multicall() {
    case "$prog_name" in
        grab) echo "install auto" ;;
        grab-add-repo) echo "add-repo auto" ;;
        grab-de) echo "de auto" ;;
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
    repo_name=""

    case "$action" in
        add-repo)
            if [[ $# -gt 0 ]] && provider="$(provider_from_flag "$1")"; then
                shift
            fi
            [[ $# -gt 0 ]] || die "add-repo requires a repository spec"
            package="$1"
            shift
            if [[ $# -gt 0 ]] && ! provider_from_flag "$1" >/dev/null 2>&1; then
                repo_name="$1"
                shift
            fi
            if [[ $# -gt 0 ]] && provider="$(provider_from_flag "$1")"; then
                shift
            fi
            [[ $# -eq 0 ]] || die "too many arguments"
            ;;
        de)
            if [[ $# -gt 0 ]] && provider="$(provider_from_flag "$1")"; then
                shift
            fi
            [[ $# -gt 0 ]] || die "de requires a desktop environment name"
            package="$1"
            shift
            if [[ $# -gt 0 ]] && provider="$(provider_from_flag "$1")"; then
                shift
            fi
            [[ $# -eq 0 ]] || die "too many arguments"
            ;;
        doctor)
            while [[ $# -gt 0 ]]; do
                case "$1" in
                    --fix|--repair)
                        doctor_fix=1
                        shift
                        ;;
                    *)
                        die "unknown doctor option: $1"
                        ;;
                esac
            done
            ;;
        selftest|managed|apps|help|version|-v|--version)
            [[ $# -eq 0 ]] || die "too many arguments"
            ;;
        list|update)
            if [[ $# -gt 0 ]] && provider="$(provider_from_flag "$1")"; then
                shift
            fi
            [[ $# -eq 0 ]] || die "too many arguments"
            ;;
        export-state)
            if [[ $# -gt 0 ]]; then
                package="$1"
                shift
            fi
            [[ $# -eq 0 ]] || die "too many arguments"
            ;;
        import-state)
            if [[ $# -gt 0 ]]; then
                package="$1"
                shift
            fi
            [[ -n "$package" ]] || die "import-state requires a file path"
            [[ $# -eq 0 ]] || die "too many arguments"
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

            [[ $# -eq 0 ]] || die "too many arguments"
            ;;
    esac
}

init_cli_context() {
    if [[ "$prog_name" == "grab" ]]; then
        case "${1:-}" in
            ""|help|-h|--help) action="help" ;;
            version|-v|--version) action="version" ;;
            *) action="install" ;;
        esac
        if [[ "$action" != "install" ]]; then
            shift || true
        fi
        parse_action_args "auto" "$@"
        return
    fi

    if [[ "$prog_name" == "grab-add-repo" ]]; then
        case "${1:-}" in
            ""|help|-h|--help) action="help" ;;
            version|-v|--version) action="version" ;;
            *) action="add-repo" ;;
        esac
        if [[ "$action" != "add-repo" ]]; then
            shift || true
        fi
        parse_action_args "auto" "$@"
        return
    fi

    if [[ "$prog_name" == "grab-de" ]]; then
        case "${1:-}" in
            ""|help|-h|--help) action="help" ;;
            version|-v|--version) action="version" ;;
            *) action="de" ;;
        esac
        if [[ "$action" != "de" ]]; then
            shift || true
        fi
        parse_action_args "auto" "$@"
        return
    fi

    if [[ "$prog_name" == "tiny" || "$prog_name" == "tinypm" ]]; then
        action="${1:-help}"
        case "$action" in
            i) action="install" ;;
            s) action="search" ;;
            r|rm|del) action="remove" ;;
            u|up|upgrade) action="update" ;;
            l|ls) action="list" ;;
            v) action="version" ;;
            st) action="start" ;;
            addrepo|add-repo) action="add-repo" ;;
        esac
        shift || true
        parse_action_args "auto" "$@"
        return
    fi

    read -r action provider < <(dispatch_multicall)
    parse_action_args "$provider" "$@"
}
