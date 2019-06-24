#!/bin/bash

. $(dirname $(dirname $(readlink -f $0)))/basic_functions.sh
. $ROOT_DIR/setup_routines.sh

astrill_image='astrill-ubuntu'
USERNAME=$RUN_USER
PASSWORD=password

main () 
{
	build_image $astrill_image <<-EOL
	FROM ubuntu:18.04
	COPY ./astrill-setup-linux64.deb /root
	RUN apt-get update \\
	    && apt-get install -y openssl libssl-dev \\
	    && useradd -m -p \$(openssl passwd -1 $PASSWORD) -s /bin/bash $USERNAME \\
	    && usermod -aG sudo $USERNAME \\
	    && apt-get install -y libgtk2.0-0 && apt-get --fix-broken install \\
	    && apt-get install -y gtk2-engines-pixbuf gtk2-engines-murrine gnome-themes-standard \\
	    && apt-get install -y canberra-gtk-module \\
	    && dpkg -i /root/astrill-setup-linux64.deb \\
	    && apt-get autoremove
	USER $USERNAME
	ENV HOME /home/$USERNAME
	CMD /usr/local/Astrill/astrill
EOL

	if [ "X$1" = 'X' ]; then
		docker run -it --rm \
			-e DISPLAY=$DISPLAY \
			-v /tmp/.X11-unix:/tmp/.X11-unix \
			$astrill_image
	else
		docker run -it \
			-e DISPLAY=$DISPLAY \
			-v /tmp/.X11-unix:/tmp/.X11-unix \
			--name "$1" \
			$astrill_image
	fi

}

maintain()
{
	[ "$1" = 'help' ] && show_help_exit
}

show_help_exit()
{
	cat << EOL

EOL
	exit 0
}

maintain "$@"; main "$@"; exit $?


