#/bin/bash

#check to see if the device is connected to the network
ip route get 1 2>/dev/null || exit 1

ip_current=$(ip route get 1 | awk '{print $7}')
interface_current=$(ip route get 1 | awk '{print $5}')
network_current="$(ip route | grep $interface_current | grep -v default | awk '{print $1}')"
ronin_data_dir=$1

_backup_network_info(){
    echo -e "ip=${ip_current}\nnetwork=${network_current}\n" > "${ronin_data_dir}/ip.txt"
    chown ronindojo:ronindojo "${ronin_data_dir}"/ip.txt
}

_set_uwf_rules() {
    ufw allow from "${network_current}" to any port "80" >/dev/null
    ufw allow from "${network_current}" to any port "22" >/dev/null
    ufw reload
}

if [ ! -f /mnt/usb/backup/ip.txt ]; then
    _set_uwf_rules
    _backup_network_info
    exit
fi

. "${ronin_data_dir}"/ip.txt

if [ "${network}" = "${network_current}" ]; then
    return 0
elif ufw status | head -n 1 | grep "Status: active" >/dev/null; then
    # uncomment if you want rules from previous network to be removed
    #while ufw status | grep "${network}"; do
    #    ufw status numbered | grep "${network}" | head -n 1 | sed -E 's/\[\s*([0-9]+)\].*/\1/' | xargs -n 1 ufw --force delete
    #done
    _set_uwf_rules
    _backup_network_info
else 
    return 1
fi