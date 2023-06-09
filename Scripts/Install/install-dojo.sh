#!/bin/bash

##############################
# LOADING VARS AND FUNCTIONS #
##############################

# shellcheck source=./Scripts/defaults.sh
. "$HOME"/RoninDojo/Scripts/defaults.sh

# shellcheck source=./Scripts/generated-credentials.sh
. "$HOME"/RoninDojo/Scripts/generated-credentials.sh

# shellcheck source=./Scripts/functions.sh
. "$HOME"/RoninDojo/Scripts/functions.sh

_load_user_conf


##############
# ASSERTIONS #
##############

if ! findmnt "${install_dir}"; then
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

#######################
# INSTALLING TOOLSETS #
#######################

_print_message "Installing RoninUI..."
if [ ! -d "${ronin_ui_path}" ]; then
    _ronin_ui_install
else
    _ronin_debian_ui
fi
_install_gpio

########################
# DOWNLOADING CODEBASE #
########################

_print_message "Downloading latest RoninDojo release..."

cd "$HOME" || exit
git clone -q "${samourai_repo}" dojo 
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

if sudo test -d "${dojo_backup_electrs}"/_data; then # Found electrs previous install.
    _print_message "Found indexer salvage to be of type electrs, setting it up..."
    _set_electrs

elif sudo test -d "${dojo_backup_indexer}"/_data; then # Found addrindexrs previous install.
    _print_message "Found indexer salvage to be of type addrindexrs"
    _set_addrindexrs

elif sudo test -d "${dojo_backup_fulcrum}"/_data; then # Found fulcrum previous install.
    _print_message "Found indexer salvage to be of type fulcrum, setting it up..."
    _set_fulcrum

else # No indexer found or fresh install
    _print_message "Found no indexer salvage, setting indexer to default (electrs)..."
    _set_electrs
fi


###################
# INSTALLING DOJO #
###################

_print_message "Please see Wiki for FAQ, help, and so much more..."
_print_message "https://wiki.ronindojo.io"
_print_message "Installing Samourai Wallet's Dojo..."

sudo systemctl restart --quiet docker

wait

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

    _print_message "Any previous node data will now be salvaged..."
    [ $# -eq 0 ] && _pause continue

    _stop_dojo

    $dojo_data_bitcoind_backup && _dojo_data_bitcoind_restore
    $dojo_data_indexer_backup && _dojo_data_indexer_restore
    $tor_backup && _tor_restore

    _start_dojo

fi


######################
# CLEANING UP BACKUP #
######################

if findmnt "${backup_mount}" ; then
    sudo umount "${backup_mount}"
    sudo rm -rf "${backup_mount}" 
fi


#####################
# INSTALL BOLTZMANN #
#####################

_print_message "Installing Boltzmann Calculator..."
_install_boltzmann


############
# FINALIZE #
############

_print_message "All RoninDojo feature installations complete!"

[ $# -eq 0 ] && _pause return
