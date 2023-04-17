#!/bin/bash

# shellcheck source=./Scripts/defaults.sh
. "$HOME"/RoninDojo/Scripts/defaults.sh

# shellcheck source=./Scripts/functions.sh
. "$HOME"/RoninDojo/Scripts/functions.sh

_load_user_conf

OPTIONS=(1 "Start"
         2 "Stop"
         3 "Restart"
         4 "Logs"
         5 "Next Page"
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
            if _is_dojo_running; then
                _print_message "Dojo is already started!"
                _sleep
                _pause return
                bash -c "${ronin_dojo_menu}"
            else
                if [ ! -d "${dojo_path}" ]; then
                    _is_dojo "${ronin_dojo_menu}"
                    exit
                fi
                _print_message "Starting Dojo..."
                _sleep

                cd "${dojo_path_my_dojo}" || exit
                _source_dojo_conf

                # Start docker containers
                ./dojo.sh start
            fi
            # checks if dojo is running (check the db container), if running, tells user to dojo has already started

            _pause return

            bash -c "${ronin_dojo_menu}"
            # press any key to return to menu
            ;;
        2)
            _stop_dojo
            _pause return

            bash -c "${ronin_dojo_menu}"
            # press any key to return to menu
            ;;
        3)
            if [ ! -d "${dojo_path}" ]; then
                _is_dojo "${ronin_dojo_menu}"
                exit
            fi
            _print_message "Restarting Dojo..."
            _sleep

            cat <<DOJO
${red}
***
Stopping Dojo...
***
${nc}
DOJO
            # Check if db container running before stopping all containers
            _stop_dojo
            cat <<DOJO
${red}
***
Starting Dojo...
***
${nc}
DOJO
                
            cd "${dojo_path_my_dojo}" || exit
            # Start docker containers
            ./dojo.sh start
            # restart dojo

            _pause return
            bash -c "${ronin_dojo_menu}"
            # press any key to return to menu

            ;;
        4)
            if [ ! -d "${dojo_path}" ]; then
                _is_dojo "${ronin_dojo_menu}"
                exit
            fi

            bash "$HOME"/RoninDojo/Scripts/Menu/menu-dojo-logs.sh
            exit
            ;;
        5)
            bash -c "${ronin_dojo_menu2}"
            exit
            ;;
        6)
            ronin
            exit
            ;;
esac