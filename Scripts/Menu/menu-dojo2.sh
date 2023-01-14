#!/bin/bash

# shellcheck source=./Scripts/defaults.sh
. "$HOME"/RoninDojo/Scripts/defaults.sh

# shellcheck source=./Scripts/functions.sh
. "$HOME"/RoninDojo/Scripts/functions.sh

OPTIONS=(1 "Clean Dojo"
         2 "Dojo Version"
         3 "Receive Block Data from Backup"
         4 "Send Block Data to Backup"
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
            if [ ! -d "${dojo_path}" ]; then
                _is_dojo "${ronin_dojo_menu2}"
                exit
            fi

            _print_message "Deleting docker dangling images and images of previous versions..."
            _sleep
            cd "$dojo_path_my_dojo" || exit
            ./dojo.sh clean

            _pause return
            bash -c "${ronin_dojo_menu2}"
            # free disk space by deleting docker dangling images and images of previous versions. then returns to menu
            ;;
        2)
            if [ ! -d "${dojo_path}" ]; then
                _is_dojo "${ronin_dojo_menu2}"
                exit
            fi
            _print_message "Displaying the version info..."
            _sleep
            cd "$dojo_path_my_dojo" || exit
            ./dojo.sh version
            # display dojo version info

            _pause return
            bash -c "${ronin_dojo_menu2}"
            # press any key to return
            ;;
        3)
            if [ ! -d "${dojo_path}" ]; then
                _is_dojo "${ronin_dojo_menu2}"
                exit
            fi
            # is dojo installed?

            bash "$HOME"/RoninDojo/Scripts/Install/install-receive-block-data.sh
            # copy block data from backup drive
            ;;
        4)
            if [ ! -d "${dojo_path}" ]; then
                _is_dojo "${ronin_dojo_menu2}"
                exit
            fi
            # is dojo installed?

            bash "$HOME"/RoninDojo/Scripts/Install/install-send-block-data.sh
            # copy block data to backup drive
            ;;
        *)
            bash -c "${ronin_dojo_menu}"
            # return to main menu
            ;;
esac
