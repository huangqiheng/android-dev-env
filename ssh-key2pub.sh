#!/bin/bash

. $(dirname $(readlink -f $0))/basic_functions.sh

main () 
{
	check_apt openssh-client

	privateKey=$(readlink -f $1)
	publicKey=$privateKey.pub

	if [ ! -f $privateKey ]; then
		echo 'source private key not exists'
		return 1
	fi

	ssh-keygen -f $privateKey -y > $publicKey
}

main "$@"; exit $?

