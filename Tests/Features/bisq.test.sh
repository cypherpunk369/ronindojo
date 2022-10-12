#! /bin/sh
# shellcheck source=Tests/Features/bisq.test.sh disable=SC2154 
# see https://github.com/kward/shunit2 

set -e

###########
# IMPORTS #
###########

. ./Tests/test-functions.sh

#########################
# TEST SCRIPT EXECUTION #
#########################

bisq_install_script="Scripts/Features/bisq.sh"
dojo_install_script="Scripts/Features/samourai-dojo.sh"

dojo_path_my_dojo="$HOME/dojo/docker/my-dojo"
ronin_data_dir="$HOME/.config/RoninDojo/data"
bisq_install_proof="${ronin_data_dir}/bisq.txt"
dojo_path_bitcoin_restart_sh="${dojo_path_my_dojo}/bitcoin/restart.sh"

#ip_current=$(ip route get 1 | awk '{print $7}')

oneTimeSetUp() {
	printTestProgress "doing oneTimeSetUp"

	! test -e "${bisq_install_proof}" || fail "Found installation proof before tests even ran."
	! test -e "${dojo_path_bitcoin_restart_sh}" || fail "Found the dojo downloaded before tests even ran."

	printTestProgress "completed oneTimeSetUp"
}

setUp() {
	printTestProgress "doing setUp"
	bash -c "${dojo_install_script} download" || fail "calling ${dojo_install_script} download returned false"
	printTestProgress "completed setUp"
}

tearDown() {
    [ "${_shunit_name_}" = 'EXIT' ] && return 0 #SHUNIT2 BUG WORKAROUND, PREVENTS ERRONEOUS CALL ON TEST FRAMEWORK EXIT

	printTestProgress "doing tearDown"
	rm -f "${bisq_install_proof}" || fail "removing ${bisq_install_proof} returned false"
	bash -c "${dojo_install_script} remove" || fail "calling ${dojo_install_script} download returned false"
	printTestProgress "completed tearDown"
}

oneTimeTearDown() {
	printTestProgress "doing oneTimeTearDown"

	! test -e "${bisq_install_proof}" || fail "Found installation proof after all tests have run."
	! test -e "${dojo_path_bitcoin_restart_sh}" || fail "Found the dojo downloaded after all tests have run."

	printTestProgress "completed oneTimeTearDown"
}

testRunScriptInstall1() {
	printTestProgress "running bisq install"
	bash -c "${bisq_install_script} install" || fail "calling ${bisq_install_script} install returned false"
	printTestProgress "bisq install completed"
	
	printTestProgress "running assertions"

	test -e "${bisq_install_proof}" || fail "Installation proof missing"
	grep -c "\-peerbloomfilters=1" "${dojo_path_bitcoin_restart_sh}" || fail "Could not find the peerbloomfilters argument set to 1."
	grep -c "\-whitelist=bloomfilter" "${dojo_path_bitcoin_restart_sh}" || fail "Could not find the whitelist argument set for the bloomfilter."

	printTestProgress "assertions completed"
}

testRunScriptInstall2() {
	printTestProgress "running bisq install"
	bash -c "${bisq_install_script} install" || fail "calling ${bisq_install_script} install returned false"
	printTestProgress "bisq install completed"

	printTestProgress "running bisq install again"
	! bash -c "${bisq_install_script} install" || fail "calling ${bisq_install_script} install without first uninstalling returned true"
	printTestProgress "testing bisq double install completed"
}

testRunScriptUninstall1() {

	printTestProgress "running bisq install"
	bash -c "${bisq_install_script} install" || fail "calling ${bisq_install_script} install returned false"
	printTestProgress "bisq install completed"

	printTestProgress "running bisq uninstall"
	bash -c "${bisq_install_script} uninstall" || fail "calling ${bisq_install_script} uninstall returned false"
	printTestProgress "bisq uninstall completed"

	printTestProgress "running assertions"

	! test -e "${bisq_install_proof}" || fail "Installation proof still present"
	! grep -c "\-peerbloomfilters=1" "${dojo_path_bitcoin_restart_sh}" || fail "Found the peerbloomfilters argument set to 1."
	! grep -c "\-whitelist=bloomfilter" "${dojo_path_bitcoin_restart_sh}" || fail "Found a whitelist argument set for the bloomfilter."

	printTestProgress "assertions completed."
}

. shunit2
