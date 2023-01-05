#!/bin/bash

# shellcheck source=./Scripts/defaults.sh
. "$HOME"/RoninDojo/Scripts/defaults.sh

# shellcheck source=./Scripts/functions.sh
. "$HOME"/RoninDojo/Scripts/functions.sh

OPTIONS=(1 "Task Manager"
         2 "Debug Tool"
         3 "Check Temperature"
         4 "Check Network Stats"
         5 "Go Back")

CHOICE=$(dialog --clear \
                --title "$TITLE" \
                --menu "$MENU" \
                "$HEIGHT" "$WIDTH" "$CHOICE_HEIGHT" \
                "${OPTIONS[@]}" \
                2>&1 >/dev/tty)

clear

case $CHOICE in
    1)
        cat <<EOF
${red}
***
Use Ctrl+C at any time to exit Task Manager...
***
${nc}
EOF
        _sleep 3

        htop
        bash -c "${ronin_system_monitoring}"
        # returns to menu
        ;;
    2)
        bash "${HOME}"/RoninDojo/Scripts/debug.sh
        bash -c "${ronin_system_monitoring}"
        ;;
    3)
        cat <<EOF
${red}
***
Showing CPU temp...
***
${nc}
EOF
        _sleep
        cpu=$(cat /sys/class/thermal/thermal_zone0/temp)
        tempC=$((cpu/1000))
        echo $tempC $'\xc2\xb0'C
        # cpu temp info

        _pause return
        bash -c "${ronin_system_monitoring}"
        # press any key to return to menu
        ;;
    4)
        cat <<EOF
${red}
***
Showing network stats...
***
${nc}
EOF
        _sleep
        ifconfig eth0 | grep 'inet'
        network_rx=$(ifconfig eth0 | grep 'RX packets' | awk '{ print $6$7 }' | sed 's/[()]//g')
        network_tx=$(ifconfig eth0 | grep 'TX packets' | awk '{ print $6$7 }' | sed 's/[()]//g')
        echo "        Receive: $network_rx"
        echo "        Transmit: $network_tx"
        # network info, use wlan0 for wireless

        _pause return
        bash -c "${ronin_system_monitoring}"
        # press any key to return to menu
        ;;
    5)
        bash -c "${ronin_system_menu}"
        # returns to menu
        ;;
esac
