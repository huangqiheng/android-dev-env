#!/bin/bash

. $(dirname $(readlink -f $0))/basic_functions.sh
. $ROOT_DIR/setup_routines.sh

main () 
{
	check_apt openssl

	userName="$1"
	passWord="$2"

	empty_exists $userName 'UserName'
	empty_exists $passWord 'PassWord'

	if [ "$passWord" = 'remove' ]; then
		userdel -r -f "$userName"
		return
	fi

	if [ -d "/home/$userName" ]; then
		useradd    -p $(openssl passwd -1 $passWord) -s /bin/bash $userName
	else
		useradd -m -p $(openssl passwd -1 $passWord) -s /bin/bash $userName
	fi

	usermod -aG sudo $userName

	cd /home/$userName
	mkdir -p .ssh
	chmod 700 .ssh

	cd .ssh
	touch authorized_keys
	chmod 600 authorized_keys

	chown $userName:$userName /home/$userName 
}

maintain()
{
	check_sudo
	[ "$1" = 'help' ] && show_help_exit $2
}

show_help_exit()
{
	cat << EOL
	sudo sh sudo-user.sh USERNAME PASSWORD
	sudo sh sudo-user.sh USERNAME remove
EOL
	exit 0
}
maintain "$@"; main "$@"; exit $?
