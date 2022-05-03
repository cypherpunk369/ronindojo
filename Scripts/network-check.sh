#/bin/bash

ip_current=$(ip route get 1 | awk '{print $7}')
interface_current=$(ip route get 1 | awk '{print $5}')
network_current="$(ip route | grep $interface_current | grep -v default | awk '{print $1}')"
ronin_data_dir=$1

_ufw_rule_add(){
    network=$1
    port=$2

    if ! sudo ufw status | grep "${network}" >/dev/null; then
        sudo ufw allow from "$network" to any port "$port" >/dev/null
    fi
}

_backup_network_info(){
    echo -e "ip=${ip_current}\nnetwork=${network_current}\n" >> "${ronin_data_dir}/ip.txt"
}

if [ ! -f /mnt/usb/backup/ip.txt ]; then
    _backup_network_info
    exit
fi

. /mnt/usb/backup/ip.txt

if "${network}" == "${network_current}"; then
    return 0
elif sudo ufw status | grep "Status: active" >/dev/null; then
    #uncomment if you want rules from previous network to be removed
    #while sudo ufw status | grep "${network}"; do
    #    sudo ufw status numbered | grep "${network}" | head -n 1 | sed -E 's/\[\s*([0-9]+)\].*/\1/' | xargs -n 1 sudo ufw --force delete
    #done
    _ufw_rule_add "${network_current}" "80"
    _ufw_rule_add "${network_current}" "22"
    sudo ufw reload
    _backup_network_info
else 
    return 1
fi