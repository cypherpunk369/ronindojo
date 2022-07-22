#!/bin/bash
# shellcheck source=Scripts/Features/mempool.sh

dojo_path_my_dojo="$HOME/dojo/docker/my-dojo"

_install_mempool() {
	sed -i -e 's/MEMPOOL_INSTALL=.*$/MEMPOOL_INSTALL=on/' "${dojo_path_my_dojo}"/conf/docker-mempool.conf
}

_uninstall_mempool() {
	sed -i 's/MEMPOOL_INSTALL=.*$/MEMPOOL_INSTALL=off/' "$dojo_path_my_dojo"/conf/docker-mempool.conf
}

case $1 in
    install)
        _install_mempool
    ;;
    uninstall)
        _uninstall_mempool
    ;;
    *)
        echo "Unknown option '$1'"
        exit 1
    ;;
esac
