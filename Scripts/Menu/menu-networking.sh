#!/bin/bash

# shellcheck source=./Scripts/defaults.sh
. "$HOME"/RoninDojo/Scripts/defaults.sh

# shellcheck source=./Scripts/functions.sh
. "$HOME"/RoninDojo/Scripts/functions.sh

_load_user_conf

OPTIONS=(1 "Firewall"
         2 "Secure Shell (SSH)"
         3 "Go Back")

CHOICE=$(dialog --clear \
                --title "$TITLE" \
                --menu "$MENU" \
                "$HEIGHT" "$WIDTH" "$CHOICE_HEIGHT" \
                "${OPTIONS[@]}" \
                2>&1 >/dev/tty)

clear
case $CHOICE in
    1)
        bash -c "${ronin_firewall_menu}"
        ;;
    2)
        bash -c "${ronin_ssh_menu}"
        ;;
    *)
        bash -c "${ronin_system_menu2}"
        ;;
esac
