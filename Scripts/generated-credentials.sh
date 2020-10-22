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
GUI_API=$(tr -dc 'a-zA-Z0-9' </dev/urandom | fold -w 32 | head -n 1)
GUI_JWT=$(tr -dc 'a-zA-Z0-9' </dev/urandom | fold -w 32 | head -n 1)

#
# Samourai Dojo Credentials
#

# Bitcoin Daemon
RPC_PASS=$(tr -dc 'a-zA-Z0-9' </dev/urandom | fold -w 32 | head -n 1)
RPC_USER=$(tr -dc 'a-zA-Z0-9' </dev/urandom | fold -w 32 | head -n 1)

# Node.js
NODE_API_KEY=$(tr -dc 'a-zA-Z0-9' </dev/urandom | fold -w 64 | head -n 1)
NODE_JWT_SECRET=$(tr -dc 'a-zA-Z0-9' </dev/urandom | fold -w 64 | head -n 1)
NODE_ADMIN_KEY=$(tr -dc 'a-zA-Z0-9' </dev/urandom | fold -w 32 | head -n 1)

# MySQL
MYSQL_ROOT_PASSWORD=$(tr -dc 'a-zA-Z0-9' </dev/urandom | fold -w 64 | head -n 1)
MYSQL_USER=$(tr -dc 'a-zA-Z0-9' </dev/urandom | fold -w 12 | head -n 1)
MYSQL_PASSWORD=$(tr -dc 'a-zA-Z0-9' </dev/urandom | fold -w 64 | head -n 1)

# Bitcoin Explorer
EXPLORER_KEY=$(tr -dc 'a-zA-Z0-9' </dev/urandom | fold -w 16 | head -n 1)

# Mempool
MEMPOOL_MYSQL_USER=$(_rand_passwd)
MEMPOOL_MYSQL_PASSWORD=$(_rand_passwd)