#!/bin/bash
# shellcheck source=Scripts/Features/indexer.sh

dojo_path_my_dojo="$HOME/dojo/docker/my-dojo"

_set_fulcrum() {
    sed -i 's/INDEXER_INSTALL=.*$/INDEXER_INSTALL=on/' "${dojo_path_my_dojo}"/conf/docker-indexer.conf
    sed -i 's/INDEXER_INSTALL=.*$/INDEXER_TYPE=fulcrum/' "${dojo_path_my_dojo}"/conf/docker-indexer.conf
    sed -i 's/NODE_ACTIVE_INDEXER=.*$/NODE_ACTIVE_INDEXER=local_indexer/' "${dojo_path_my_dojo}"/conf/docker-node.conf

    return 0
}

_set_electrs() {
    sed -i 's/INDEXER_INSTALL=.*$/INDEXER_INSTALL=on/' "${dojo_path_my_dojo}"/conf/docker-indexer.conf
    sed -i 's/INDEXER_INSTALL=.*$/INDEXER_TYPE=electrs/' "${dojo_path_my_dojo}"/conf/docker-indexer.conf
    sed -i 's/NODE_ACTIVE_INDEXER=.*$/NODE_ACTIVE_INDEXER=local_indexer/' "${dojo_path_my_dojo}"/conf/docker-node.conf

    return 0
}

_set_addrindexrs() {
    sed -i 's/INDEXER_INSTALL=.*$/INDEXER_INSTALL=on/' "${dojo_path_my_dojo}"/conf/docker-indexer.conf
    sed -i 's/INDEXER_INSTALL=.*$/INDEXER_TYPE=addrindexrs/' "${dojo_path_my_dojo}"/conf/docker-indexer.conf
    sed -i 's/NODE_ACTIVE_INDEXER=.*$/NODE_ACTIVE_INDEXER=local_indexer/' "${dojo_path_my_dojo}"/conf/docker-node.conf

    return 0
}

case $1 in
    fulcrum)
        _set_fulcrum
    ;;
    electrs)
        _set_electrs
    ;;
    addrindexrs)
        _set_addrindexrs
    ;;
    *)
        echo "Unknown option '$1'"
        exit 1
    ;;
esac
