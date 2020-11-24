#!/bin/bash

. $(dirname $(readlink -f $0))/basic_functions.sh

main () 
{
	check_sudo

	if cmd_exists prosody; then
		log 'prosody is exists'
		exit 0
	fi


	if [ ! -f /etc/apt/sources.list.d/prosody.list ]; then
		 wget https://prosody.im/files/prosody-debian-packages.key -O- | sudo apt-key add -
		 echo deb http://packages.prosody.im/debian $(lsb_release -sc) main | tee /etc/apt/sources.list.d/prosody.list

		check_update f
	fi

	check_apt prosody 
}

main "$@"; exit $?

