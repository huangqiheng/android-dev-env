#!/bin/bash

. $(f='basic_functions.sh'; while [ ! -f $f ]; do f="../$f"; done; readlink -f $f)

main () 
{
	check_sudo

	if [ "$1" = "undo" ]; then
		apt-get install --reinstall nodejs-legacy     # fix /usr/bin/node
		n rm 6.0.0     # replace number with version of Node that was installed
		npm uninstall -g n
		exit 0
	fi

	check_apt npm
	npm cache clean -f
	npm install -g n
	n stable

	ln -sf "/usr/local/n/versions/node/$1/bin/node" /usr/bin/nodejs
	n $1
}

main "$@"; exit $?

