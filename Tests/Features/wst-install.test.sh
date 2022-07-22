#! /bin/sh
# shellcheck source=Tests/Features/wst-install.test.sh disable=SC2154 
# see https://github.com/kward/shunit2 

set -e

wst_install_script="Scripts/Features/wst.sh"
wst_path="${HOME}/Whirlpool-Stats-Tool"

oneTimeSetUp() {
	echo "doing oneTimeSetUp"

	! test -e "${wst_path}" || fail "oneTimeSetUp couldn't start, ${wst_path} already exists"

	echo "completed oneTimeSetUp"
}

tearDown() {
    [ "${_shunit_name_}" = 'EXIT' ] && return 0 #SHUNIT2 BUG WORKAROUND, PREVENTS ERRONEOUS CALL ON TEST FRAMEWORK EXIT

	echo "doing tearDown"

    cd "${wst_path}" || exit 1
    pipenv --rm
    cd -

	rm -rf "${wst_path}"
	! test -e "${wst_path}" || fail "tearDown couldn't clean up, ${wst_path} still exists"

	echo "completed tearDown"
}

testRunScript1() {
	echo "running wst install"
	bash -c "${wst_install_script} install" || fail "calling ${wst_install_script} install returned false"
	echo "wst install completed"
	
	echo "running assertions"
	test -d "${wst_path}" || fail "missing directory after calling ${wst_install_script} install"
	cd "${wst_path}"
	pipenv --venv || fail "pipenv did not make a virtualenv for ${wst_path}"
	cd -
	echo "assertions completed"
}

testRunScript2() {
	echo "running wst install"
	bash -c "${wst_install_script} install" || fail "calling ${wst_install_script} install returned false"
	echo "wst install completed"

	echo "running wst install again"
	bash -c "${wst_install_script} install" && fail "calling ${wst_install_script} install without first uninstalling returned true"
	echo "wst install completed"
}

. shunit2
