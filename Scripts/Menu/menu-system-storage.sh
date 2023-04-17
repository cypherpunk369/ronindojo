#!/bin/bash

# shellcheck source=./Scripts/defaults.sh
. "$HOME"/RoninDojo/Scripts/defaults.sh

# shellcheck source=./Scripts/functions.sh
. "$HOME"/RoninDojo/Scripts/functions.sh

_load_user_conf

OPTIONS=(1 "Check Disk Space"
         2 "Format & Mount New Backup Drive"
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
        _print_message "Showing Disk Space Info..."
        _sleep

        sd_free_ratio=$(printf "%s" "$(df | grep "/$" | awk '{ print $4/$2*100 }')") 2>/dev/null
        sd=$(printf "%s (%s%%)" "$(df -h | grep '/$' | awk '{ print $4 }')" "${sd_free_ratio}")
        echo "Internal: ${sd} remaining"
        hdd_free_ratio=$(printf "%s" "$(df  | grep "${install_dir}" | awk '{ print $4/$2*100 }')") 2>/dev/null
        hdd=$(printf "%s (%s%%)" "$(df -h | grep "${install_dir}" | awk '{ print $4 }')" "${hdd_free_ratio}")
        echo "External: ${hdd} remaining"
        # disk space info

        _pause return
        bash -c "${ronin_system_storage}"
        exit
        ;;
    2)
        bash "$HOME"/RoninDojo/Scripts/Install/install-new-backup-data-drive.sh
        bash -c "${ronin_system_storage}"
        exit
        ;;
    3)
        bash -c "${ronin_system_menu}"
        # returns to menu
        ;;
esac
