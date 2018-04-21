#!/bin/bash

. $(dirname $(readlink -f $0))/basic_functions.sh

main () 
{
	check_sudo

	if [ "$1" = "undo" ]; then
		apt-get install --reinstall nodejs-legacy     # fix /usr/bin/node
		n rm 6.0.0     # replace number with version of Node that was installed
		npm uninstall -g n
		exit 0
	fi

	npm cache clean -f
	npm install -g n
	n stable

	ln -sf "/usr/local/n/versions/node/$1/bin/node" /usr/bin/nodejs
	n $1
}

main "$@"; exit $?

