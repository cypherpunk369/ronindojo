#!/bin/bash

set -o pipefail

# shellcheck source=./Scripts/defaults.sh
. "$HOME"/RoninDojo/Scripts/defaults.sh

# shellcheck source=./Scripts/functions.sh
. "$HOME"/RoninDojo/Scripts/functions.sh

_load_user_conf

OPTIONS=(1 "Start"
         2 "Stop"
         3 "Restart"
         4 "Status"
         5 "Logs"
         6 "Reset"
         7 "Re-install"
         8 "Go Back")

CHOICE=$(dialog --clear \
                --title "$TITLE" \
                --menu "$MENU" \
                "$HEIGHT" "$WIDTH" "$CHOICE_HEIGHT" \
                "${OPTIONS[@]}" \
                2>&1 >/dev/tty)

clear
case $CHOICE in
	1)
        # Check if process running, otherwise start it
        if pm2 describe "RoninUI" | grep status | grep stopped 1>/dev/null; then
            _print_message "Starting Ronin UI..."
            _sleep
            cd "${ronin_ui_path}" || exit

            pm2 start "RoninUI"
        else
            _print_message "Ronin UI already started..."
            _sleep
        fi

        _pause return
        # press to return is needed so the user has time to see outputs

        bash -c "${ronin_ui_menu}"
        # start Ronin UI, return to menu
        ;;
    2)
        # Check if process running before stopping it
        if pm2 describe "RoninUI" &>/dev/null; then
            _print_message "Stopping Ronin UI..."
            _sleep
            cd "${ronin_ui_path}" || exit

            pm2 stop "RoninUI"
        else
            _print_message "Ronin UI already stopped..."
        fi

        _pause return
        # press to return is needed so the user has time to see outputs

        bash -c "${ronin_ui_menu}"
        # start Ronin UI, return to menu
        ;;
    3)
        _print_message "Restarting Ronin UI..."
        _sleep
        cd "${ronin_ui_path}" || exit

        pm2 restart "RoninUI" 1>/dev/null
        # restart service

        _pause return
        # press to return is needed so the user has time to see outputs

        bash -c "${ronin_ui_menu}"
        # start Ronin UI, return to menu
        ;;
    4)
        _print_message "Showing Ronin UI Status..."
        cd "${ronin_ui_path}" || exit
        pm2 status

        _pause return
        bash -c "${ronin_ui_menu}"
        ;;
    5)
        _print_message "Showing Ronin UI Logs..."
        _print_message 'Press "q" key to exit at any time...'

        cd "${ronin_ui_path}" || exit

        _sleep 5 # Workaround until a proper FIX!!!
        less --force logs/combined.log

        bash -c "${ronin_ui_menu}"
        ;;
    6)
        _print_message "Resetting Ronin UI..."

        cd "${ronin_ui_path}" || exit

        test -f ronin-ui.dat && rm ronin-ui.dat

        _pause return

        bash -c "${ronin_ui_menu}"
        ;;
    7)
        _print_message "Re-installing Ronin UI..."
        _ronin_ui_uninstall
        _ronin_ui_install

        pm2 status

        _pause return
        bash -c "${ronin_ui_menu}"
        ;;
    *)
        ronin
        # returns to main menu
        ;;
esac
