#! /bin/bash
# shellcheck source=/dev/null

#############
# FUNCTIONS #
#############

_print_banner() {
    charCount=$(expr length "$1" + 4)
    printf '#%.0s' $(seq 1 $charCount) 
    echo ""
    echo "# ${1} #"
    printf '#%.0s' $(seq 1 $charCount) 
    echo ""
    echo ""
}

printTestProgress() {
    echo "@"
    echo "@ ${1}"
    echo "@"
    echo ""
    echo ""
}
