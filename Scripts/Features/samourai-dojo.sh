#!/bin/bash
# shellcheck source=Scripts/Features/samourai-dojo.sh

###########
# IMPORTS #
###########

SCRIPT=$(readlink -f "$0")
SCRIPTPATH=$(dirname "$SCRIPT")

. $SCRIPTPATH/../Functions/packages.sh

#############
# CONSTANTS #
#############

samourai_repo='https://code.samourai.io/ronindojo/samourai-dojo.git'
samourai_path="${HOME}/dojo"

#############
# FUNCTIONS #
#############

_download_dojo() {
	cd "$HOME" || exit 1
	git clone -q "${samourai_repo}" dojo
	cd - || exit 1

	# cd "${samourai_path}" || exit
	# git checkout -q -f "${samourai_commitish}"
}

_initialize_dojo() {
	
}

_remove_dojo() {
	rm -rf "${samourai_path}"
}

####################
# SCRIPT EXECUTION #
####################

case $1 in
    download)
        _download_dojo
    ;;
    initialize)
		_initialize_dojo
	;;
    _remove_dojo)
        _remove_dojo
    ;;
    *)
        echo "Unknown option '$1'"
        exit 1
    ;;
esac
