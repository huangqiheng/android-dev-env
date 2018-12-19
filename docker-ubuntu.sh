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
		echo "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" > \
			/etc/apt/sources.list.d/docker.list
		check_update f
	fi

	check_apt docker-ce
	enable_docker
}

enable_docker()
{
	usermod -aG docker "$RUN_USER"
	systemctl enable docker
	systemctl start docker

	log_y '--- Try: "docker run hello-world" ---'
	log_y '--- REBOOT, if necessary ---'
}

auto_script()
{
	check_sudo

	cd $CACHE_DIR
	if [ ! -f get-docker.sh ]; then
		curl -fsSL get.docker.com -o get-docker.sh
	fi

	sh get-docker.sh --mirror Aliyun

	enable_docker
	exit
}

maintain()
{
	[ "$1" = 'auto' ] && auto_script && exit
	[ "$1" = 'help' ] && show_help_exit $2
}

show_help_exit()
{
	cat << EOL

EOL
	exit 0
}
maintain "$@"; main "$@"; exit $?
