#!/bin/bash
# shellcheck source=Scripts/Features/boltzmann.sh

SCRIPT=$(readlink -f "$0")
SCRIPTPATH=$(dirname "$SCRIPT")

. $SCRIPTPATH/../Functions/packages.sh

boltzmann_repo='https://code.samourai.io/oxt/boltzmann.git'
boltzmann_pkg_dependencies=("python" "python-pipenv")
boltzmann_local_repo_dir_name='boltzmann'
boltzmann_path="$HOME/boltzmann"

_install_boltzmann() {
    cd "$HOME" || exit 1

    git clone -q "${boltzmann_repo}" "${boltzmann_local_repo_dir_name}"
    cd "${boltzmann_local_repo_dir_name}" || exit 1

    _install_pkg_if_missing "${boltzmann_pkg_dependencies[@]}"

    pipenv install -r requirements.txt
    pipenv install sympy numpy
}

_uninstall_boltzmann() {
    cd "$HOME" || exit
    rm -rf "$boltzmann_path"
}


case $1 in
    install)
        _install_boltzmann
    ;;
    uninstall)
        _uninstall_boltzmann
    ;;
    *)
        echo "Unknown option '$1'"
        exit 1
    ;;
esac
