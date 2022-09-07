#!/bin/bash
# shellcheck source=/dev/null disable=SC2154

. "$HOME"/RoninDojo/Scripts/defaults.sh
. "$HOME"/RoninDojo/Scripts/functions.sh

OPTIONS=(1 "Bitcoind"
         2 "MariaDB"
         3 "Indexer"
         4 "Node.js"
         5 "Tor"
         6 "Whirlpool"
         7 "Error Logs"
         8 "All Logs"
         9 "Go Back")

CHOICE=$(dialog --clear \
                --title "$TITLE" \
                --menu "$MENU" \
                "$HEIGHT" "$WIDTH" "$CHOICE_HEIGHT" \
                "${OPTIONS[@]}" \
                2>&1 >/dev/tty)

clear
case $CHOICE in
        1|2|3|4|5|6|8)
            if ! _is_dojo_running; then
                _print_message "Please start Dojo first!"
                _sleep 5
                bash -c "$HOME"/RoninDojo/Scripts/Menu/menu-dojo-logs.sh
                exit
            fi
            cd "${dojo_path_my_dojo}" || exit
            _print_message "Press Ctrl + C to exit at any time..."
            _sleep
            ;;
esac
case $CHOICE in
        1)
            ./dojo.sh logs bitcoind
            ;;
        2)
            ./dojo.sh logs db
            ;;
        3)
            _fetch_configured_indexer_type
            indexer=$?

            if ((indexer==3)); then
                _print_message "No indexer installed..."
                _sleep
                _print_message "Install using the applications install menu..."
                _sleep
            
            elif ((indexer==2)); then
                _print_message "Fulcrum Server is your current Indexer..."
                _sleep

                ./dojo.sh logs fulcrum

            elif ((indexer==1)); then
                _print_message "SW Addrindexrs is your current Indexer..."
                _sleep

                ./dojo.sh logs indexer

            elif ((indexer==0)); then
                _print_message "Electrs is your current Indexer..."
                _sleep

                ./dojo.sh logs electrs

            else
                _print_message "Something went wrong! Contact support..."
                _sleep
            fi
            ;;
        4)
            ./dojo.sh logs node
            ;;
        5)
            ./dojo.sh logs tor
            ;;
        6)
            ./dojo.sh logs whirlpool
            ;;
        7)
            bash "$HOME"/RoninDojo/Scripts/Menu/menu-dojo-error-logs.sh
            exit
            ;;
        8)
            ./dojo.sh logs
            ;;
        9)
            bash -c "${ronin_dojo_menu}"
            exit
            ;;
esac

_pause return
bash -c "$HOME"/RoninDojo/Scripts/Menu/menu-dojo-logs.sh
exit
