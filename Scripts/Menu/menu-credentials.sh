#!/bin/bash
# shellcheck source=/dev/null disable=SC2154

. "$HOME"/RoninDojo/Scripts/defaults.sh
. "$HOME"/RoninDojo/Scripts/dojo-defaults.sh
. "$HOME"/RoninDojo/Scripts/functions.sh

_load_user_conf

OPTIONS=(1 "Dojo"
         2 "Whirlpool"
         3 "Electrs"
         4 "Mempool"
         5 "Ronin UI"
         6 "Bitcoind"
         7 "All Credentials"
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
            cat <<EOF
${red}
***
Samourai Dojo Credentials
***
${nc}

${red}
***
WARNING: Do not share these onion addresses with anyone!
***
${nc}

Maintenance Tool:
Tor Address             = http://${tor_addr_dojo_api}/admin
Admin Key               = $NODE_ADMIN_KEY
API Key                 = $NODE_API_KEY
EOF
                _pause return
                bash -c "${ronin_credentials_menu}"
                # press any key to return to menu
                # shows samouraio dojo credentials and returns to menu
                ;;
        2)
            cat <<EOF
${red}
***
Samourai Whirlpool Credentials
***
${nc}

${red}
***
WARNING: Do not share these onion addresses with anyone!
***
${nc}

Tor Address             = http://${tor_addr_whirlpool}
Whirlpool API Key       = ${whirlpool_api_key:-Whirlpool not Initiated yet. Pair wallet with GUI}
EOF
            _pause return
            bash -c "${ronin_credentials_menu}"
            # press any key to return to menu
            # shows whirlpool credentials and returns to menu
            ;;
        3)
            if _is_electrs; then
                cat <<EOF
${red}
***
Electrs Credentials
***
${nc}

Tor Address             = http://${tor_addr_electrs}
EOF
                # displaying electrs tor address to connect to electrum

                cat <<EOF
${red}
***
Check the RoninDojo Wiki for pairing information at https://wiki.ronindojo.io
***
${nc}
EOF
            fi

            _sleep

            _pause return
            bash -c "${ronin_credentials_menu}"
            # return to menu
            ;;
        4)
            if ! _is_mempool ; then
                cat <<EOF
${red}
***
Mempool Space Visualizer is not installed...
***
${nc}
EOF
                _sleep
                cat <<EOF
${red}
***
Install using the manage applications menu...
***
${nc}
EOF
                _sleep

                _pause return
                bash -c "${ronin_credentials_menu}"
            else
                cat <<EOF
${red}
***
Mempool Space Visualizer Credentials
***

***
${nc}
Tor Address             =  http://${tor_addr_mempool}
EOF

                _pause return
                bash -c "${ronin_credentials_menu}"
                # press any key to return to menu
                # see defaults.sh
                fi
                ;;
        5)
            _ronin_ui_credentials && cd "$HOME" || exit

            cat <<EOF
${red}
***
Ronin UI Credentials
***
${nc}

Local Access Domain     =   http://ronindojo.local
Local Access IP         =   http://${ip} # fallback for when ronindojo.local doesn't work for you.
Tor Address             =   http://${BACKEND_TOR}
EOF
            _pause return
            bash -c "${ronin_credentials_menu}"
            # shows Ronin UI credentials, returns to menu
            ;;
        6)
            cat <<EOF
${red}
***
Bitcoin Credentials
***
${nc}

Bitcoin Daemon:

Tor Address             = http://${tor_addr_bitcoind}
RPC User                = $BITCOIND_RPC_USER
RPC Password            = $BITCOIND_RPC_PASSWORD
RPC IP                  = $BITCOIND_IP
RPC Port                = $BITCOIND_RPC_PORT

Bitcoin RPC Explorer (No username required):
Tor Address             = http://${tor_addr_explorer}
Password                = $EXPLORER_KEY
EOF
            _pause return
            bash -c "${ronin_credentials_menu}"
            # press any key to return to menu
            # shows bitcoind and btc rpc explorer credentials and returns to menu
            ;;
        7)
            _ronin_ui_credentials && cd "$HOME" || exit
            cat <<EOF
${red}
***
Displaying list of all available credentials in your RoninDojo...
***
${nc}
EOF
            _sleep 5 --msg "Displaying in "

            cat <<EOF
${red}
***
Samourai Dojo Credentials
***

***
WARNING: Do not share these onion addresses with anyone!
***
${nc}

Maintenance Tool:
Tor Address             = http://${tor_addr_dojo_api}/admin
Admin Key               = $NODE_ADMIN_KEY
API Key                 = $NODE_API_KEY

${red}
***
Samourai Whirlpool Credentials
***

***
WARNING: Do not share these onion addresses with anyone!
***
${nc}

Tor Address             = http://${tor_addr_whirlpool}
Whirlpool API Key       = ${whirlpool_api_key:-Whirlpool not Initiated yet. Pair wallet with GUI}

${red}
***
Ronin UI Credentials
***
${nc}

Local Access Domain     =   http://ronindojo.local
Local Access IP         =   http://${ip} # fallback for when ronindojo.local doesn't work for you.
Tor Address             =   http://${BACKEND_TOR}

${red}
***
Bitcoin Credentials
***
${nc}

Bitcoin Daemon:

Tor Address             = http://${tor_addr_bitcoind}
RPC User                = $BITCOIND_RPC_USER
RPC Password            = $BITCOIND_RPC_PASSWORD
RPC IP                  = $BITCOIND_IP
RPC Port                = $BITCOIND_RPC_PORT

Bitcoin RPC Explorer (No username required):
Tor Address                 = http://${tor_addr_explorer}
Password                = $EXPLORER_KEY
EOF
            if [ -f "${dojo_path_my_dojo}"/indexer/electrs.toml ]; then
                cat <<EOF
${red}
***
Electrs Credentials
***
${nc}

Tor Address             = http://${tor_addr_electrs}
EOF
            fi

            if _is_mempool; then
                cat <<EOF
${red}
***
Mempool Space Visualizer Credentials
***
${nc}
Tor Address             = http://${tor_addr_mempool}
EOF
            fi

            _pause return
            bash -c "${ronin_credentials_menu}"
            # press any key to return to menu
            # shows all credentials and returns to menu
            ;;
        8)
            ronin
            # returns to main menu
            ;;
esac