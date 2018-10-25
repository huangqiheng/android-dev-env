#!/bin/bash

. $(dirname $(readlink -f $0))/basic_functions.sh
. $THIS_DIR/setup_routines.sh

main () 
{
	if [ ! -f $HOME/sslocal.json ]; then
		log 'Please prepare the sslocal.json file'
		exit 1
	fi

	full_sources
	check_update f

	check_apt xinit ratpoison 

	cloudinit_remove
	auto_login
	auto_startx

	check_apt shadowsocks proxychains 
	ratpoisonrc "exec sslocal $HOME/sslocal.json &"

	install_astrill
	check_apt socat 
	ratpoisonrc "exec socat tcp-listen:3128,reuseaddr,fork tcp:localhost:3213 &"
	ratpoisonrc "exec /usr/local/Astrill/astrill"

	check_apt tor
	set_conf /etc/tor/torrc
	set_conf Socks5Proxy '127.0.0.1:7070' ' '
	set_conf SOCKSPort '0.0.0.0:9050' ' '
	set_conf /etc/tor/torsocks.conf
	set_conf TorAddress '0.0.0.0'
	systemctl restart tor

	check_apt xauth
	set_conf /etc/ssh/sshd_config
	set_conf X11Forwarding yes ' '
	set_conf X11DisplayOffset 10 ' '
	cat /var/run/sshd.pid | xargs kill -1

	cat >$HOME/.ssh/config <<EOL
Host *
  ForwardAgent yes
  ForwardX11 yes
EOL

}

fix_gpt_auto_error()
{
	set_conf /etc/default/grub
	set_conf GRUB_CMDLINE_LINUX_DEFAULT '"systemd.gpt_auto=0"'
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


