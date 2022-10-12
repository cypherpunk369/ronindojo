#!/bin/bash
# shellcheck source=Scripts/Features/bisq.sh

#############
# CONSTANTS #
#############

ronin_data_dir="$HOME/.config/RoninDojo/data"
bisq_install_proof="${ronin_data_dir}/bisq.txt"
ip_current=$(ip route get 1 | awk '{print $7}')
dojo_path_my_dojo="$HOME/dojo/docker/my-dojo"
bitcoind_restart_sh="${dojo_path_my_dojo}/bitcoin/restart.sh"

#############
# FUNCTIONS #
#############

_bisq_install(){
    mkdir -p "${ronin_data_dir}"

    if grep -c "\-peerbloomfilters=1" "${bitcoind_restart_sh}"; then
        echo "Previous bisq installation found, please remove it first."
        exit 1
    fi

    if grep -c "\-whitelist=bloomfilter" "${bitcoind_restart_sh}"; then
        echo "Previous bisq installation found, please remove it first."
        exit 1
    fi

    sed -i \
        -e "/  -txindex=1/i\  -peerbloomfilters=1" \
        -e "/  -txindex=1/i\  -whitelist=bloomfilter@${ip_current}" \
        "${bitcoind_restart_sh}"

    touch "${bisq_install_proof}"
}

_bisq_uninstall() {
    sed -i \
        -e '/-peerbloomfilters=1/d' \
        -e "/-whitelist=bloomfilter@${ip_current}/d" \
        "${bitcoind_restart_sh}"

    rm "${bisq_install_proof}"
}

####################
# SCRIPT EXECUTION #
####################

case $1 in
    install)
        _bisq_install
    ;;
    uninstall)
        _bisq_uninstall
    ;;
    *)
        echo "Unknown option '$1'"
        exit 1
    ;;
esac
