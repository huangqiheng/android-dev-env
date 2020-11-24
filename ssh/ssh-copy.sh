#!/bin/bash

. $(dirname $(dirname $(readlink -f $0)))/basic_functions.sh


private_key="${KEY:-$HOME/.ssh/id_rsa}"
public_key="$private_key.pub"

main () 
{
	if ! cmd_exists ssh-copy-id; then
		check_apt openssh-client
	fi

	if [ ! -f $private_key ]; then
		ssh-keygen -b 2048 -t rsa -f "$private_key" -q -N ""
	fi

	ssh-keygen -f $private_key -y > $public_key
	ssh-copy-id -i $private_key $@
}

main "$@"; exit $?

