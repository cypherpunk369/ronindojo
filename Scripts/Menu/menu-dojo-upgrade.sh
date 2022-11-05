#!/bin/bash
# shellcheck source=/dev/null disable=SC2154


####################
# SOURCE FUNCTIONS #
####################

. "$HOME"/RoninDojo/Scripts/defaults.sh
. "$HOME"/RoninDojo/Scripts/functions.sh
. "$HOME"/RoninDojo/Scripts/update.sh


####################
# BACKUP THE CONFS #
####################


_backup_dojo_confs


#############
# STOP DOJO #
#############


_stop_dojo


###########
# UPDATES #
###########


# Create Updates history directory
test ! -d "$HOME"/.config/RoninDojo/data/updates && mkdir -p "$HOME"/.config/RoninDojo/data/updates

# Remove any existing docker-mempool.conf in favor of new tpl for v2 during upgrade
test -f "$HOME"/.config/RoninDojo/data/updates/22-* || _update_22


##################
# LOAD VARIABLES #
##################


_load_user_conf


#############
# STABILIZE #
#############


_check_dojo_perms "${dojo_path_my_dojo}"

if grep BITCOIND_RPC_EXTERNAL=off "${dojo_path_my_dojo}"/conf/docker-bitcoind.conf 1>/dev/null; then
    sed -i 's/BITCOIND_RPC_EXTERNAL=.*$/BITCOIND_RPC_EXTERNAL=on/' "${dojo_path_my_dojo}"/conf/docker-bitcoind.conf
fi


#######################
# UPDATE THE CODEBASE #
#######################


_dojo_update

cd "${HOME}" || exit


####################
# UPDATE THE CONFS #
####################


# TODO: remove this code block

if _is_mempool; then
    _mempool_conf || exit
fi


#######################
# MANUALLY MIGRATE WP #
#######################


# TODO: remove this code block

if [ -f /etc/systemd/system/whirlpool.service ] ; then
   sudo systemctl stop --quiet whirlpool

   _print_message "Whirlpool will be installed via Docker..."
   _print_message "You will need to re-pair with GUI, see Wiki for more information..."
   _sleep 5
else
   _print_message "Whirlpool will be installed via Docker..."
   _print_message "For pairing information see the wiki..."
   _sleep
fi


#########################
# MANUALLY MIGRATE BISQ #
#########################


# TODO: remove this code block

if _is_bisq ; then
    _bisq_install
fi


###########################
# MIGRATE LEGACY INDEXERS #
###########################


# Migrate the electrs data to the new electrs backup data location. Must be done AFTER dojo repo has been updated
test -f "$HOME"/.config/RoninDojo/data/updates/32-* || _update_32

# TODO: remove this code block

cd "${dojo_path_my_dojo}" || exit


#######################
# EXECUTE THE UPGRADE #
#######################


# run upgrade
./dojo.sh upgrade --nolog --auto


########################
# POST UPGRADE UPDATES #
########################


# Restore indexer backup data to new docker volume location
test -f "$HOME"/.config/RoninDojo/data/updates/33-* || _update_33


##########
# RETURN #
##########

_pause return

#This next line of code is to be removed when enough users are on 1.14.0 or newer
ronin
