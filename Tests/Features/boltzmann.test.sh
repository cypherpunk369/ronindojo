#! /bin/sh
# see https://github.com/kward/shunit2

set -e

boltzmann_install_script="Scripts/Features/boltzmann.sh"
boltzmann_path="$HOME/boltzmann"

oneTimeSetUp() {
	echo "doing oneTimeSetUp"

	! test -e "${boltzmann_path}" || fail "oneTimeSetUp couldn't start, ${boltzmann_path} already exists"

	echo "completed oneTimeSetUp"
}

oneTimeTearDown() {
	echo "doing oneTimeTearDown"

	rm -rf "${boltzmann_path}"
	! test -e "${boltzmann_path}" || fail "oneTimeTearDown couldn't clean up, ${boltzmann_path} still exists"

	echo "completed oneTimeTearDown"
}

testRunScript() {
	echo "running boltzmann.sh" install
	bash -c "${boltzmann_install_script} install" || fail "calling ${boltzmann_install_script} install returned false"
	echo "boltzmann-install.sh completed"
	
	echo "running assertions"
	test -d "${boltzmann_path}" || fail "missing directory after calling ${boltzmann_install_script}"
	echo "assertions completed"
}

. shunit2
