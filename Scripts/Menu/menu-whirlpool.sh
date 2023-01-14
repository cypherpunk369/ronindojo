#!/bin/bash

# shellcheck source=./Scripts/defaults.sh
. "$HOME"/RoninDojo/Scripts/defaults.sh

# shellcheck source=./Scripts/functions.sh
. "$HOME"/RoninDojo/Scripts/functions.sh

OPTIONS=(1 "Start"
         2 "Stop"
         3 "Restart"
         4 "Logs"
         5 "Reset"
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
            _is_dojo "${ronin_whirlpool_menu}"
            _print_message "Starting Whirlpool..."
            _sleep
            docker start whirlpool 1>/dev/null

            _print_message "Don't forget to login to GUI to unlock mixing!"
            _sleep

            _pause return

            bash -c "$ronin_whirlpool_menu"
            # see defaults.sh
            # start whirlpool, press to return to menu
            ;;
        2)
            _is_dojo "${ronin_whirlpool_menu}"
            _print_message "Stopping Whirlpool..."
            _sleep
            docker stop whirlpool 1>/dev/null

            _pause return

            bash -c "$ronin_whirlpool_menu"
            # stop whirlpool, press to return to menu
            # see defaults.sh
            ;;
        3)
            _is_dojo "${ronin_whirlpool_menu}"
            _print_message "Restarting Whirlpool..."
            _sleep
            docker stop whirlpool 1>/dev/null

            docker start whirlpool 1>/dev/null
            _sleep

            _pause return

            bash -c "$ronin_whirlpool_menu"
            # enable whirlpool at startup, press to return to menu
            # see defaults.sh
	        ;;
        4)
            _is_dojo "${ronin_whirlpool_menu}"
            _print_message "Viewing Whirlpool Logs..."
            _sleep
            _print_message "Press Ctrl+C to exit at anytime..."
            cd "$dojo_path_my_dojo" || exit
            ./dojo.sh logs whirlpool

            bash -c "$ronin_whirlpool_menu"
            # view logs, return to menu
            # see defaults.sh
            ;;
        5)
            _is_dojo "${ronin_whirlpool_menu}"
            _print_message "Re-initiating Whirlpool will reset your mix count and generate new API key..."
            _sleep
            _print_message "Are you sure you want to re-initiate Whirlpool?"

            while true; do
                read -rp "[${green}Yes${nc}/${red}No${nc}]: " answer
                case $answer in
                    [yY][eE][sS]|[yY])
                        _print_message "Re-initiating Whirlpool..."
                        cd "$dojo_path_my_dojo" || exit

                        ./dojo.sh whirlpool reset
                        _sleep

                        _print_message "Re-initation complete, leave APIkey blank when pairing to GUI!"
                        _sleep 5
                        break
                        ;;
                    [nN][oO]|[Nn])
                        _pause return
                        break
                        ;;
                    *)
                        _print_message "Invalid answer! Enter Y or N"
                        ;;
                esac
            done

            _sleep

            bash -c "$ronin_whirlpool_menu"
            # re-initate whirlpool, return to menu
            # see defaults.sh
            ;;
        *)
            bash -c "${ronin_samourai_toolkit_menu}"
            # return to menu
            ;;
esac