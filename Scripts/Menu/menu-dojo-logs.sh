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
        1)
            # checks if dojo is running (check the db container), if not running tells user to start dojo first
            if ! _dojo_check; then
                cat <<EOF
${RED}
***
Please start Dojo first!
***
${NC}
EOF
                _sleep 5
                bash -c "$HOME"/RoninDojo/Scripts/Menu/menu-dojo-logs.sh
            else
                cat <<EOF
${RED}
***
Press Ctrl + C to exit at any time...
***
${NC}
EOF
              _sleep 2

              cd "${dojo_path_my_dojo}" || exit

              ./dojo.sh logs bitcoind

              bash "$HOME"/RoninDojo/Scripts/Menu/menu-dojo-logs.sh
              # shows logs for bitcoind
            fi
            ;;
        2)
            if ! _dojo_check; then
                cat <<EOF
${RED}
***
Please start Dojo first!
***
${NC}
EOF
                _sleep 5
                bash -c "$HOME"/RoninDojo/Scripts/Menu/menu-dojo-logs.sh
            else
              cat <<EOF
${RED}
***
Press Ctrl + C to exit at any time...
***
${NC}
EOF
              _sleep 2
              cd "${dojo_path_my_dojo}" || exit
              ./dojo.sh logs db
              bash "$HOME"/RoninDojo/Scripts/Menu/menu-dojo-logs.sh
              # shows logs for db
            fi
            ;;
        3)
            if ! _dojo_check; then
                cat <<EOF
${RED}
***
Please start Dojo first!
***
${NC}
EOF
                _sleep 5
                bash -c "$HOME"/RoninDojo/Scripts/Menu/menu-dojo-logs.sh
            else
                if grep "INDEXER_INSTALL=on" "${dojo_path_my_dojo}"/conf/docker-indexer.conf 1>/dev/null && [ -f "${dojo_path_my_dojo}"/indexer/electrs.toml ] ; then
                    cat <<EOF
${RED}
***
Electrum Rust Server is your current Indexer...
***
${NC}
EOF
                    _sleep 2
                    cat <<EOF
${RED}
***
Please check Electrum Rust Server logs instead...
***
${NC}
EOF
                    _sleep 2

                    _pause return
                    bash "$HOME"/RoninDojo/Scripts/Menu/menu-dojo-logs.sh
                    exit 1
                else
                    cat <<EOF
${RED}
***
No indexer installed...
***
${NC}
EOF
                    _sleep 2
                    cat <<EOF
${RED}
***
Install using the applications install menu...
***
${NC}
EOF
                    _sleep 2

                    _pause return

                    bash "$HOME"/RoninDojo/Scripts/Menu/menu-dojo-logs.sh
                    exit
                fi

              cat <<EOF
${RED}
***
Press Ctrl + C to exit at any time...
***
${NC}
EOF
              _sleep 2

              cd "${dojo_path_my_dojo}" || exit

              ./dojo.sh logs indexer

              bash "$HOME"/RoninDojo/Scripts/Menu/menu-dojo-logs.sh
              # shows logs for nginx
            fi
            ;;
        4)
            if ! _dojo_check; then
                cat <<EOF
${RED}
***
Please start Dojo first!
***
${NC}
EOF
                _sleep 5
                bash -c "$HOME"/RoninDojo/Scripts/Menu/menu-dojo-logs.sh
            else
              cat <<EOF
${RED}
***
Press Ctrl + C to exit at any time...
***
${NC}
EOF
              _sleep 2
              cd "${dojo_path_my_dojo}" || exit
              ./dojo.sh logs node
              bash "$HOME"/RoninDojo/Scripts/Menu/menu-dojo-logs.sh
              # shows logs for nodejs
            fi
            ;;
        5)
            if ! _dojo_check; then
                cat <<EOF
${RED}
***
Please start Dojo first!
***
${NC}
EOF
                _sleep 5
                bash -c "$HOME"/RoninDojo/Scripts/Menu/menu-dojo-logs.sh
            else
              cat <<EOF
${RED}
***
Press Ctrl + C to exit at any time...
***
${NC}
EOF
              _sleep 2

              cd "${dojo_path_my_dojo}" || exit
              ./dojo.sh logs tor
              bash "$HOME"/RoninDojo/Scripts/Menu/menu-dojo-logs.sh
              # shows logs for tor
            fi
            ;;
        6)
            if ! _dojo_check; then
                cat <<EOF
${RED}
***
Please start Dojo first!
***
${NC}
EOF
                _sleep 5
                bash -c "$HOME"/RoninDojo/Scripts/Menu/menu-dojo-logs.sh
            else
              _sleep 2

              cat <<EOF
${RED}
***
Press Ctrl+C to exit at anytime...
***
${NC}
EOF
              cd "${dojo_path_my_dojo}" || exit
              ./dojo.sh logs whirlpool
              bash -c "$HOME"/RoninDojo/Scripts/Menu/menu-dojo-logs.sh
              # view logs, return to menu
              # see defaults.sh
            fi
            ;;
        7)
            bash "$HOME"/RoninDojo/Scripts/Menu/menu-dojo-error-logs.sh
            # goes to error logs menu
            ;;
        8)
            if ! _dojo_check; then
                cat <<EOF
${RED}
***
Please start Dojo first!
***
${NC}
EOF
                _sleep 5
                bash -c "$HOME"/RoninDojo/Scripts/Menu/menu-dojo-logs.sh
            else
              _sleep 2

              cat <<EOF
${RED}
***
Press Ctrl+C to exit at anytime...
***
${NC}
EOF
              cd "${dojo_path_my_dojo}" || exit
              ./dojo.sh logs
              bash -c "$HOME"/RoninDojo/Scripts/Menu/menu-dojo-logs.sh
              # view logs, return to menu
              # see defaults.sh
            fi
            ;;
        9)
            bash -c "${RONIN_DOJO_MENU}"
            # goes back to ronin dojo menu
            ;;
esac
