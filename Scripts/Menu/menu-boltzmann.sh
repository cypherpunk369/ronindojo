#!/bin/bash

# shellcheck source=./Scripts/defaults.sh
. "$HOME"/RoninDojo/Scripts/defaults.sh
# shellcheck source=./Scripts/dojo-defaults.sh
. "$HOME"/RoninDojo/Scripts/dojo-defaults.sh
# shellcheck source=./Scripts/functions.sh
. "$HOME"/RoninDojo/Scripts/functions.sh

if [ ! -d "${boltzmann_path}" ]; then
    _print_message "Installing Boltzmann..."

    _sleep

    _install_boltzmann
fi

# checks if ${HOME}/boltzmann dir exists, if so kick back to menu
cat << 'EOF'
    __          ____                                  
   / /_  ____  / / /_____  ____ ___  ____ _____  ____ 
  / __ \/ __ \/ / __/_  / / __ `__ \/ __ `/ __ \/ __ \
 / /_/ / /_/ / / /_  / /_/ / / / / / /_/ / / / / / / /
/_.___/\____/_/\__/ /___/_/ /_/ /_/\__,_/_/ /_/_/ /_/ 
A python script computing the entropy of Bitcoin transactions
    and the linkability of their inputs and outputs.

EOF
    
cat <<EOF
Example Usage:

${red}
Single txid
${nc}
8e56317360a548e8ef28ec475878ef70d1371bee3526c017ac22ad61ae5740b8

${red}
Multiple txids
${nc}
8e56317360a548e8ef28ec475878ef70d1371bee3526c017ac22ad61ae5740b8,812bee538bd24d03af7876a77c989b2c236c063a5803c720769fc55222d36b47,...
EOF

cd "${boltzmann_path}"/boltzmann || exit

# Export required environment variables
export BOLTZMANN_RPC_USERNAME=${BITCOIND_RPC_USER}
export BOLTZMANN_RPC_PASSWORD=${BITCOIND_RPC_PASSWORD}

# shellcheck disable=SC2154
export BOLTZMANN_RPC_HOST=${BITCOIND_IP}
# shellcheck disable=SC2154
export BOLTZMANN_RPC_PORT=${BITCOIND_RPC_PORT}

# Loop command until user quits
while true
do
    printf "\nEnter a txid or multiple txids separated by commas. Type [Q|Quit] to exit boltzmann\n"
    read -r txids

    if [[ "$txids" =~ (Q|q|Quit|quit) ]]; then
        break
    fi

    if ! pipenv run python ludwig.py --rpc --txids="${txids}"; then
        echo "Could not get tx information"
    fi
done

bash -c "${ronin_samourai_toolkit_menu}"
exit
