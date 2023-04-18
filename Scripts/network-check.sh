#!/bin/bash

##############
# ASSERTIONS #
##############

#check to see if the device is connected to the network
ip route get 1 2>/dev/null || exit 1

#############
# VARIABLES #
#############

ip_current=$(ip route get 1)
ip_current=$(echo "${ip_current}" | awk '{print $7}')

interface_current=$(ip route get 1)
interface_current=$(echo "${interface_current}" | awk '{print $5}')

network_current=$(ip route)
network_current=$(echo "${network_current}" | grep "${interface_current}")
network_current=$(echo "${network_current}" | grep -v default)
network_current=$(echo "${network_current}" | awk '{print $1}')

ronin_data_dir=$1
ronin_username=$2

#############
# FUNCTIONS #
#############

_backup_network_info(){
    echo -e "ip=${ip_current}\nnetwork=${network_current}\n" > "${ronin_data_dir}/ip.txt"
    chown "${ronin_username}:${ronin_username}" "${ronin_data_dir}"/ip.txt
}

_set_uwf_rules() {
    ufw allow from "${network_current}" to any port "80" >/dev/null
    ufw allow from "${network_current}" to any port "22" >/dev/null
    ufw reload
}

#################
# THE PROCEDURE #
#################

if [ ! -f "${ronin_data_dir}"/ip.txt ]; then
    _set_uwf_rules
    _backup_network_info
    exit
fi

# shellcheck source=/dev/null
. "${ronin_data_dir}"/ip.txt

# shellcheck disable=SC2154
if [ "${network}" = "${network_current}" ]; then
    exit
elif (ufw status || true) | (head -n 1 || true) | grep "Status: active" >/dev/null; then
    # uncomment if you want rules from previous network to be removed
    #while ufw status | grep "${network}"; do
    #    ufw status numbered | grep "${network}" | head -n 1 | sed -E 's/\[\s*([0-9]+)\].*/\1/' | xargs -n 1 ufw --force delete
    #done
    _set_uwf_rules
    _backup_network_info
else 
    echo "UFW found to be not active!"
    exit 1
fi