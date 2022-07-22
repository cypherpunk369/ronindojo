#! /bin/sh
# see https://github.com/kward/shunit2

set -e

wst_install_script="Scripts/Features/wst.sh"
wst_path="${HOME}/Whirlpool-Stats-Tool"

oneTimeSetUp() {
	echo "doing oneTimeSetUp"

	! test -e "${wst_path}" || fail "oneTimeSetUp couldn't start, ${wst_path} already exists"

	echo "completed oneTimeSetUp"
}

oneTimeTearDown() {
	echo "doing oneTimeTearDown"

	! test -e "${wst_path}" || fail "oneTimeTearDown couldn't clean up, ${wst_path} still exists"

	echo "completed oneTimeTearDown"
}

setUp() {
	echo "doing setUp"

	bash -c "${wst_install_script} install"

	echo "completed setUp"
}

tearDown() {
	echo "doing tearDown"

	rm -rf "${wst_path}"
	! test -e "${wst_path}" || fail "tearDown couldn't clean up, ${wst_path} still exists"

	echo "completed tearDown"
}

testRunScript() {
	echo "running wst uninstall"
	bash -c "${wst_install_script} uninstall" || fail "calling ${wst_install_script} uninstall returned false"
	echo "wst uninstall completed"

	echo "running assertions"
	! test -e "${wst_path}" || fail "file ${wst_path} still exists after calling ${wst_install_script} uninstall"
	echo "assertions completed."

	#TODO: do the pipenv venv check
}

. shunit2
