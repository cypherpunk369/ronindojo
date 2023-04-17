#!/bin/bash

# shellcheck source=./Scripts/defaults.sh
. "$HOME"/RoninDojo/Scripts/defaults.sh

# shellcheck source=./Scripts/functions.sh
. "$HOME"/RoninDojo/Scripts/functions.sh

_load_user_conf

OPTIONS=(1 "Networking"
         2 "Change User Password"
         3 "Change Root Password"
         4 "Lock Root User"
         5 "Unlock Root User"
         6 "Go Back")

CHOICE=$(dialog --clear \
                --title "$TITLE" \
                --menu "$MENU" \
                "$HEIGHT" "$WIDTH" "$CHOICE_HEIGHT" \
                "${OPTIONS[@]}" \
                2>&1 >/dev/tty)

clear
case $CHOICE in
    1)
        bash -c "${ronin_networking_menu}"
        exit
        ;;
    2)
        _print_message "Prepare to type new password for ${ronindojo_user} user..."
        _sleep
        sudo passwd "${ronindojo_user}"
        ;;
    3)
        _print_message "Prepare to type new password for root user..."
        _sleep
        sudo passwd
        ;;
    4)
        _print_message "Locking Root User..."
        _sleep
        sudo passwd -l root
        ;;
    5)
        _print_message "Unlocking Root User..."
        _sleep
        sudo passwd -u root
        ;;
    6)
        bash -c "${ronin_system_menu}"
        exit
        ;;
esac

_pause return
bash -c "${ronin_system_menu2}"
