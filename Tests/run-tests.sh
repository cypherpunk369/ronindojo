#! /bin/bash
# shellcheck source=/dev/null disable=SC3030,SC3024,SC3054

###########
# IMPORTS #
###########

. ./Tests/test-functions.sh

#########################
# TEST SCRIPT EXECUTION #
#########################

allSuccess=true
failures=()

_print_banner "SETTING UP TESTING ENVIRONMENT"

mkdir -p /var/log/shunit2/Tests/Features
pacman --quiet -Syyu --noconfirm archlinux-keyring

_print_banner "STARTING TESTCASES"

for testFile in Tests/Features/*.test.sh; do

    _print_banner "TESTING ${testFile}"

    bash "${testFile}" > "/var/log/shunit2/${testFile}.log" 2>&1 
    if [ $? -ne 0 ]; then
        allSuccess=false
        failures+=("${testFile}")
    fi

    echo ""
done

_print_banner "TESTING FINISHED"

#################################
# TEST SCRIPT RESULT COLLECTION #
#################################

if ! $allSuccess; then

    _print_banner "FAILURES"

    for failure in "${failures[@]}"; do
        _print_banner "TESTCASE OUTPUT ${failure}"
        echo ""
        cat "/var/log/shunit2/${failure}.log"
    done

    _print_banner "DONE PRINTING FAILURES"

    exit 1
else
    _print_banner "Success in all tests!"
fi
