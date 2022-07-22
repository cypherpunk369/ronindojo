#!/bin/bash
# shellcheck source=Scripts/Features/bisq.sh

ronin_data_dir="$HOME/.config/RoninDojo/data"
ip_current=$(ip route get 1 | awk '{print $7}')
dojo_path_my_dojo="$HOME/dojo/docker/my-dojo"

_bisq_install(){
    mkdir -p "${ronin_data_dir}"

    sed -i -e "/  -txindex=1/i\  -peerbloomfilters=1" \
        -e "/  -txindex=1/i\  -whitelist=bloomfilter@${ip_current}" "${dojo_path_my_dojo}"/bitcoin/restart.sh

    touch "${ronin_data_dir}"/bisq.txt
}

_bisq_uninstall() {
    sed -i -e '/-peerbloomfilters=1/d' \
        -e "/-whitelist=bloomfilter@${ip_current}/d" "${dojo_path_my_dojo}"/bitcoin/restart.sh

    rm "${ronin_data_dir}"/bisq.txt
}

case $1 in
    install)
        _install_bisq
    ;;
    uninstall)
        _bisq_uninstall
    ;;
    *)
        echo "Unknown option '$1'"
        exit 1
    ;;
esac
