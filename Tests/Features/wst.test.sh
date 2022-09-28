#! /bin/sh
# shellcheck source=Tests/Features/wst.test.sh disable=SC2154 
# see https://github.com/kward/shunit2 

set -e

###########
# IMPORTS #
###########

. ./Tests/test-functions.sh

#########################
# TEST SCRIPT EXECUTION #
#########################

wst_install_script="Scripts/Features/wst.sh"
wst_path="${HOME}/Whirlpool-Stats-Tool"

oneTimeSetUp() {
	printTestProgress "doing oneTimeSetUp"

	! test -e "${wst_path}" || fail "oneTimeSetUp couldn't start, ${wst_path} already exists"

	printTestProgress "completed oneTimeSetUp"
}

tearDown() {
    [ "${_shunit_name_}" = 'EXIT' ] && return 0 #SHUNIT2 BUG WORKAROUND, PREVENTS ERRONEOUS CALL ON TEST FRAMEWORK EXIT

	printTestProgress "doing tearDown"

	if [ -d "${wst_path}" ]; then
	    cd "${wst_path}" || exit 1
	    pipenv --rm
	    cd -

		# pipenv --venv && fail "pipenv still had a virtualenv for ${wst_path}"
		rm -rf "${wst_path}"
		! test -e "${wst_path}" || fail "tearDown couldn't clean up, ${wst_path} still exists"
	fi

	printTestProgress "completed tearDown"
}

oneTimeTearDown() {
	printTestProgress "doing oneTimeTearDown"

	! test -e "${wst_path}" || fail "oneTimeTearDown found it not cleaned up, ${wst_path} still exists"

	printTestProgress "completed oneTimeTearDown"
}

testRunScriptInstall1() {
	printTestProgress "running wst install"
	bash -c "${wst_install_script} install" || fail "calling ${wst_install_script} install returned false"
	printTestProgress "wst install completed"
	
	printTestProgress "running assertions"
	test -d "${wst_path}" || fail "missing directory after calling ${wst_install_script} install"
	cd "${wst_path}"
	pipenv --venv || fail "pipenv did not make a virtualenv for ${wst_path}"
	cd -
	printTestProgress "assertions completed"
}

testRunScriptInstall2() {
	printTestProgress "running wst install"
	bash -c "${wst_install_script} install" || fail "calling ${wst_install_script} install returned false"
	printTestProgress "wst install completed"

	printTestProgress "running wst install again"
	bash -c "${wst_install_script} install" && fail "calling ${wst_install_script} install without first uninstalling returned true"
	printTestProgress "testing wst double install completed"
}

testRunScriptUninstall1() {

	printTestProgress "running wst install"
	bash -c "${wst_install_script} install" || fail "calling ${wst_install_script} install returned false"
	printTestProgress "wst install completed"

	printTestProgress "running wst uninstall"
	bash -c "${wst_install_script} uninstall" || fail "calling ${wst_install_script} uninstall returned false"
	printTestProgress "wst uninstall completed"

	printTestProgress "running assertions"
	! test -e "${wst_path}" || fail "file ${wst_path} still exists after calling ${wst_install_script} uninstall"
	# pipenv --venv && fail "pipenv still had a virtualenv for ${wst_path}"
	printTestProgress "assertions completed."
}

. shunit2
