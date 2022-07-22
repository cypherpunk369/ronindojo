#!/bin/bash
# shellcheck source=Scripts/Features/wst.sh

SCRIPT=$(readlink -f "$0")
SCRIPTPATH=$(dirname "$SCRIPT")

. $SCRIPTPATH/../Functions/packages.sh

whirlpool_stats_repo='https://code.samourai.io/whirlpool/whirlpool_stats.git'
whirlpool_local_repo_dir_name="Whirlpool-Stats-Tool"
whirlpool_pkg_dependencies=("python" "python-pipenv")
whirlpool_path="${HOME}/${whirlpool_local_repo_dir_name}"

_install_wst() {
    cd "${HOME}" || exit 1

    if test -e "${whirlpool_path}"; then
        echo "Previous wst installation found, please remove it first."
        exit 1
    fi

    git clone -q "${whirlpool_stats_repo}" "${whirlpool_local_repo_dir_name}"

    _install_pkg_if_missing "${whirlpool_pkg_dependencies[@]}"

    cd "${whirlpool_path}" || exit 1

    if pipenv --venv 2>/dev/null; then
        echo "Previous wst installation found, please remove it first."
        exit 1
    fi

    pipenv install -r requirements.txt
}

_uninstall_wst() {

    cd "${whirlpool_path}" || exit 1

    pipenv --rm

    rm -rf "${whirlpool_path}"
}


case $1 in
    install)
        _install_wst
    ;;
    uninstall)
        _uninstall_wst
    ;;
    *)
        echo "Unknown option '$1'"
        exit 1
    ;;
esac
