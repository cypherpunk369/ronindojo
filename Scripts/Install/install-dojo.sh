#!/bin/bash
# shellcheck source=/dev/null disable=SC2154

##############################
# LOADING VARS AND FUNCTIONS #
##############################

. "$HOME"/RoninDojo/Scripts/defaults.sh
. "$HOME"/RoninDojo/Scripts/generated-credentials.sh
. "$HOME"/RoninDojo/Scripts/functions.sh

_load_user_conf

##############
# ASSERTIONS #
##############

if ! findmnt "${install_dir}" 1>/dev/null; then
    _print_message "Missing drive mount at ${install_dir}! Please contact support for assistance..."
    _print_message "Exiting RoninDojo..."
    [ $# -eq 0 ] && _pause return
    exit 1
fi

if [ -d "${dojo_path_my_dojo}" ]; then
    _print_message "RoninDojo is already installed..."
    _print_message "Exiting RoninDojo..."
    [ $# -eq 0 ] && _pause return
    exit 1
fi

####################
# INSTRUCTING USER #
####################

_print_message "Running RoninDojo install..."
_print_message "Use Ctrl+C to exit now if needed!"
_sleep 3 --msg "Installing in"


########################
# DOWNLOADING CODEBASE #
########################

_print_message "Downloading latest RoninDojo release..."

cd "$HOME" || exit
git clone -q "${samourai_repo}" dojo 2>/dev/null
cd "${dojo_path}" || exit
git checkout -q -f "${samourai_commitish}"

##########################
# SETTING UP CREDENTIALS #
##########################

_print_message "Credentials necessary for usernames, passwords, etc. will randomly be generated now..."
_print_message "Credentials are found in RoninDojo menu, ${dojo_path_my_dojo}/conf, or the ~/RoninDojo/user.conf.example file..."
_print_message "Be aware these credentials are used to login to Dojo Maintenance Tool, Block Explorer, and more!"
_print_message "Setting the RPC User and Password..."

_restore_or_create_dojo_confs

######################
# SETTING UP INDEXER #
######################

_set_indexer

_check_salvage_db

if (($?==2)); then # No indexer found or fresh install
    
    bash "$HOME"/RoninDojo/Scripts/Install/install-electrs-indexer.sh
    sudo rm -rf "${dojo_backup_indexer}"

elif (($?==0)); then # Found electrs previous install.
    bash "$HOME"/RoninDojo/Scripts/Install/install-electrs-indexer.sh
    sudo test -d "${dojo_backup_indexer}"/_data/db/mainnet && sudo rm -rf "${dojo_backup_indexer}"/_data/db/mainnet #remove 0.8.x data that's incompatible with 0.9+
fi

###################
# INSTALLING DOJO #
###################

_print_message "Please see Wiki for FAQ, help, and so much more..."
_print_message "https://wiki.ronindojo.io"
_print_message "Installing Samourai Wallet's Dojo..."

# Restart docker here for good measure
sudo systemctl restart --quiet docker

cd "$dojo_path_my_dojo" || exit
if ! ./dojo.sh install --nolog --auto; then
    _print_error_message "Install failed! Please contact support..."
    [ $# -eq 0 ] && _pause return
    [ $# -eq 0 ] && ronin
    exit
fi

####################
# RESTORING BACKUP #
####################

if $dojo_data_bitcoind_backup || $dojo_data_indexer_backup || $tor_backup; then

    _print_message "Any previous node data will now be salvaged if you choose to continue..."
    [ $# -eq 0 ] && _pause continue

    _stop_dojo

    $dojo_data_bitcoind_backup && _dojo_data_bitcoind_restore
    $dojo_data_indexer_backup && _dojo_data_indexer_restore
    $tor_backup && _tor_restore

    ./dojo.sh start

fi

######################
# CLEANING UP BACKUP #
######################

if findmnt "${backup_mount}" 1>/dev/null; then
    sudo umount "${backup_mount}"
    sudo rmdir "${backup_mount}" &>/dev/null
fi

############
# FINALIZE #
############

_print_message "All RoninDojo feature installations complete!"

[ $# -eq 0 ] && _pause return
