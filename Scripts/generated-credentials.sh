#!/bin/bash
# shellcheck disable=SC2034 source=/dev/null

. "$HOME"/RoninDojo/Scripts/functions.sh

#
# DO NOT EDIT THIS FILE DIRECTLY, THESE VALUES ARE AUTO GENERATED
# INSTEAD USE $HOME/.config/RoninDojo/user.conf to override these values
# see $HOME/RoninDojo/user.conf.example
#

#
# Backend GUI Credentials
#
gui_api=$(_rand_passwd 69)
gui_jwt=$(_rand_passwd 69)

#
# Samourai Dojo Credentials
#

# Bitcoin Daemon
BITCOIND_RPC_USER=$(_rand_passwd)
BITCOIND_RPC_PASSWORD=$(_rand_passwd 69)

# Node.js
NODE_API_KEY=$(_rand_passwd 69)
NODE_JWT_SECRET=$(_rand_passwd 69)
NODE_ADMIN_KEY=$(_rand_passwd 69)

# MySQL
MYSQL_ROOT_PASSWORD=$(_rand_passwd 69)
MYSQL_USER=$(_rand_passwd)
MYSQL_PASSWORD=$(_rand_passwd 69)

# Bitcoin Explorer
EXPLORER_KEY=$(_rand_passwd 69)

# Mempool Space Visualizer
MEMPOOL_MYSQL_USER=$(_rand_passwd)
MEMPOOL_MYSQL_PASS=$(_rand_passwd)
MEMPOOL_MYSQL_ROOT_PASSWORD=$(_rand_passwd)