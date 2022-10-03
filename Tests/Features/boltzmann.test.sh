#! /bin/sh
# shellcheck source=Tests/Features/boltzmann.test.sh disable=SC2154 
# see https://github.com/kward/shunit2

set -e

###########
# IMPORTS #
###########

. ./Tests/test-functions.sh

#########################
# TEST SCRIPT EXECUTION #
#########################

boltzmann_install_script="Scripts/Features/boltzmann.sh"
boltzmann_path="$HOME/boltzmann"

oneTimeSetUp() {
	printTestProgress "doing oneTimeSetUp"

	! test -e "${boltzmann_path}" || fail "oneTimeSetUp couldn't start, ${boltzmann_path} already exists"

	printTestProgress "completed oneTimeSetUp"
}

tearDown() {
    [ "${_shunit_name_}" = 'EXIT' ] && return 0 #SHUNIT2 BUG WORKAROUND, PREVENTS ERRONEOUS CALL ON TEST FRAMEWORK EXIT

	printTestProgress "doing tearDown"

	if [ -d "${boltzmann_path}" ]; then
	    cd "${boltzmann_path}" || exit 1
	    pipenv --rm
	    cd -

		# pipenv --venv && fail "pipenv still had a virtualenv for ${boltzmann_path}"
		rm -rf "${boltzmann_path}"
		! test -e "${boltzmann_path}" || fail "tearDown couldn't clean up, ${boltzmann_path} still exists"
	fi

	printTestProgress "completed tearDown"
}

oneTimeTearDown() {
	printTestProgress "doing oneTimeTearDown"

	! test -e "${boltzmann_path}" || fail "oneTimeTearDown couldn't clean up, ${boltzmann_path} still exists"

	printTestProgress "completed oneTimeTearDown"
}

testRunScriptInstall1() {
	printTestProgress "running boltzmann.sh install"
	bash -c "${boltzmann_install_script} install" || fail "calling ${boltzmann_install_script} install returned false"
	printTestProgress "boltzmann-install.sh completed"
	
	printTestProgress "running assertions"
	test -d "${boltzmann_path}" || fail "missing directory after calling ${boltzmann_install_script}"
	printTestProgress "assertions completed"
}

testRunScriptInstall2() {
	printTestProgress "running boltzmann.sh install"
	bash -c "${boltzmann_install_script} install" || fail "calling ${boltzmann_install_script} install returned false"
	printTestProgress "boltzmann.sh install completed"

	printTestProgress "running boltzmann.sh install again"
	bash -c "${boltzmann_install_script} install" && fail "calling ${boltzmann_install_script} install without first uninstalling returned true"
	printTestProgress "testing boltzmann.sh double install completed"
}

testRunScriptUninstall1() {

	printTestProgress "running boltzmann.sh install"
	bash -c "${boltzmann_install_script} install" || fail "calling ${boltzmann_install_script} install returned false"
	printTestProgress "boltzmann.sh install completed"

	printTestProgress "running boltzmann.sh uninstall"
	bash -c "${boltzmann_install_script} uninstall" || fail "calling ${boltzmann_install_script} uninstall returned false"
	printTestProgress "boltzmann.sh uninstall completed"

	printTestProgress "running assertions"
	! test -e "${boltzmann_path}" || fail "file ${boltzmann_path} still exists after calling ${boltzmann_install_script} uninstall"
	# pipenv --venv && fail "pipenv still had a virtualenv for ${boltzmann_path}"
	printTestProgress "assertions completed."
}

. shunit2
