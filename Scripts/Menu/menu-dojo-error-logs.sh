#!/bin/bash

set -o pipefail

# shellcheck source=./Scripts/defaults.sh
. "$HOME"/RoninDojo/Scripts/defaults.sh

# shellcheck source=./Scripts/functions.sh
. "$HOME"/RoninDojo/Scripts/functions.sh

OPTIONS=(1 "Bitcoind"
         2 "MariaDB"
         3 "Indexer"
         4 "Node.js"
         5 "Tor"
         6 "Go Back")

CHOICE=$(dialog --clear \
                --title "$TITLE" \
                --menu "$MENU" \
                "$HEIGHT" "$WIDTH" "$CHOICE_HEIGHT" \
                "${OPTIONS[@]}" \
                2>&1 >/dev/tty)

clear
case $CHOICE in
        1|2|3|4|5)
            _is_dojo_running
            if [ $? -ne 0 ]; then
                _print_message "Please start Dojo first!"
                _sleep 5
                bash -c "$HOME"/RoninDojo/Scripts/Menu/menu-dojo-error-logs.sh
                exit
            fi
            cd "$dojo_path_my_dojo" || exit
            _print_message "Press Ctrl + C to exit at any time..."
            _sleep
            ;;&
        1)
            ./dojo.sh logs bitcoind -n 200 | grep -i 'error'
            ;;
        2)
            ./dojo.sh logs db -n 500 | grep -i 'error'
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

                ./dojo.sh logs fulcrum -n 500 | grep -i 'error'

            elif ((indexer==1)); then
                _print_message "SW Addrindexrs is your current Indexer..."
                _sleep

                ./dojo.sh logs indexer -n 500 | grep -i 'error'

            elif ((indexer==0)); then
                _print_message "Electrs is your current Indexer..."
                _sleep

                ./dojo.sh logs electrs -n 500 | grep -i 'error'

            else
                _print_message "Something went wrong! Contact support..."
                _sleep
            fi
            ;;
        4)
            ./dojo.sh logs node -n 500 | grep -i 'error'
            ;;
        5)
            ./dojo.sh logs tor -n 500 | grep -i 'error'
            ;;
        *)
            bash "$HOME"/RoninDojo/Scripts/Menu/menu-dojo-logs.sh
            exit
            ;;
esac

_pause return
bash -c "$HOME"/RoninDojo/Scripts/Menu/menu-dojo-error-logs.sh
exit
