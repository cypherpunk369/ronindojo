#/bin/bash

. /mnt/usb/backup/ip.txt

ip_current=$(ip route get 1 | awk '{print $7}')
interface_current=$(ip route get 1 | awk '{print $5}')
network_current="$(ip route | grep $interface_current | grep -v default | awk '{print $1}')"

_ufw_rule_add(){
    ip=$1
    port=$2

    if ! sudo ufw status | grep "${ip}" &>/dev/null; then
        sudo ufw allow from "$ip" to any port "$port" &>/dev/null
    fi
}

if "${network}" == "${network_current}"; then
    return 0
elif systemctl is-active --quiet ufw.service; then
    _ufw_rule_add "${network_current}" "80"
    _ufw_rule_add "${network_current}" "22"
    sudo ufw reload
else 
    return 1
fi