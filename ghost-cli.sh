#!/bin/bash

. $(dirname $(readlink -f $0))/basic_functions.sh

main () 
{
	check_update
	setup_nodejs
	check_apt sqlite3

	npm install -g ghost-cli

	if [ "$1" = "production" ]; then
		check_apt nginx
		ufw allow 'Nginx Full'
		check_apt mysql-server
	fi
}

setup_nodejs()
{
	if command_exists /usr/bin/node; then
		log "node has been installed"
		return
	fi

	curl -sL https://deb.nodesource.com/setup_7.x | sudo -E bash -
	check_apt nodejs
}

main "$@"; exit $?
