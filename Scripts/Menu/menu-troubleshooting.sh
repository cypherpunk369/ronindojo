#!/bin/bash

# shellcheck source=./Scripts/defaults.sh
. "$HOME"/RoninDojo/Scripts/defaults.sh

# shellcheck source=./Scripts/functions.sh
. "$HOME"/RoninDojo/Scripts/functions.sh

_load_user_conf

OPTIONS=(1 "Update Operating System"
         2 "Go Back")

CHOICE=$(dialog --clear \
                --title "$TITLE" \
                --menu "$MENU" \
                "$HEIGHT" "$WIDTH" "$CHOICE_HEIGHT" \
                "${OPTIONS[@]}" \
                2>&1 >/dev/tty)

clear
case $CHOICE in
    1)
        _print_message "Updating system packages..."
        _sleep
        _print_message "Use Ctrl+C to exit if needed!"
        _sleep 10 --msg "Updating in"

        _stop_dojo
        
        _print_message "Perfoming a full system update..."
        _apt_update
        sudo apt-get -y upgrade
        
        _pause reboot
        sudo systemctl reboot
        ;;
    2)
        bash -c "${ronin_system_menu}"
        ;;
esac
