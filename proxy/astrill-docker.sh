#!/bin/bash

. $(dirname $(dirname $(readlink -f $0)))/basic_functions.sh
. $ROOT_DIR/setup_routines.sh

astrill_image='astrill-ubuntu'
USERNAME=$RUN_USER
PASSWORD=password

main () 
{
	create_image $astrill_image <<-EOL
	FROM ubuntu:18.04
	RUN buildDeps='openssl' \\
	    && apt update && apt install -y $buildDeps \\
	    && useradd -m -p \$(openssl passwd -1 $PASSWORD) -s /bin/bash $USERNAME \\
	    && usermod -aG sudo $USERNAME \\
	    && apt purge -y --auto-remove $buildDeps
	USER $USERNAME
	ENV HOME /home/$USERNAME
	CMD /usr/local/Astrill/astrill
EOL

	docker run -it --rm \
		-e DISPLAY=$DISPLAY \
		-v /tmp/.X11-unix:/tmp/.X11-unix \
		$astrill_image

}

inside_docker_exit()
{
	nocmd_udpate astrill
	x11_forward_server
	install_astrill
	astrill
	exit 0
}

maintain()
{
	[ "$1" = 'inside' ] && inside_docker_exit
}

maintain "$@"; main "$@"; exit $?


