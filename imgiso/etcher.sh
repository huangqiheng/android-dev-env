#!/bin/dash

# . $(dirname $(readlink -f $0))/basic_functions.sh
. $(dirname $(dirname $(readlink -f $0)))/basic_functions.sh

main () 
{
	if cmd_exists balena-etcher-electron; then
		log_y 'balena-etcher-electron is ready'
		exit 0
	fi

	check_sudo
	echo "deb https://deb.etcher.io stable etcher" | sudo tee /etc/apt/sources.list.d/balena-etcher.list
	apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 379CE192D401AB61
	apt-get update -y
	check_apt balena-etcher-electron
}

main "$@"; exit $?
