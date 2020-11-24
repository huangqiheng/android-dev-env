#!/bin/bash

. $(dirname $(readlink -f $0))/basic_functions.sh

main () 
{
	check_sudo

	if cmd_exists yarn; then
		log 'yarn is exists'
		exit 0
	fi


	if [ ! -f /etc/apt/sources.list.d/yarn.list ]; then
		curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
		echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
		check_update f
	fi

	check_apt yarn
}

main "$@"; exit $?

