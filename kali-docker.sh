#!/bin/dash

. $(dirname $(readlink -f $0))/basic_functions.sh
. $THIS_DIR/setup_routines.sh

main () 
{
	check_update

	clean_apt docker docker-engine docker.io
	rm -rf /var/lib/docker-engine

	check_apt apt-transport-https ca-certificates curl gnupg2 software-properties-common

	if ! apt-key fingerprint 0EBFCD88 >/dev/null 2>&1; then
		curl -fsSL https://download.docker.com/linux/debian/gpg | sudo apt-key add -
		echo "deb [arch=amd64] https://download.docker.com/linux/debian stretch stable" > \
			/etc/apt/sources.list.d/docker.list
		check_update f
	fi

	check_apt docker-ce

	usermod -aG docker "$RUN_USER"
	log_y '--- PLEASE REBOOT! ---'
}

maintain()
{
	[ "$1" = 'help' ] && show_help_exit $2
}

show_help_exit()
{
	cat << EOL

EOL
	exit 0
}
maintain "$@"; main "$@"; exit $?
