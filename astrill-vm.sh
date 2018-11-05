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
	check_update_once f

	check_apt xinit ratpoison 
	check_apt proxychains 

	cloudinit_remove
	auto_login
	auto_startx

	install_shadowsocks
	install_astrill

	setup_tor '127.0.0.1:7070'
	setup_socat 3213 3128
	setup_polipo 7070 8213

	ratpoisonrc "exec Xvfb :1 -screen 0 1920x1080x24+32 -fbdir /var/tmp &"
	ratpoisonrc "exec DISPLAY=:1 /usr/local/Astrill/astrill"
	x11_forward_server

	help_text
}

help_text()
{
	cat << EOL
  astrill: 0.0.0.0:3128
  ssocks:  0.0.0.0:7070
  tor:     0.0.0.0:9050
  http:    0.0.0.0:8213
EOL
}

install_shadowsocks()
{
	check_apt shadowsocks 
	ratpoisonrc "exec sslocal $HOME/sslocal.json &"
}

setup_socat()
{
	localport=$1
	openport=$2

	check_apt socat 
	ratpoisonrc "exec socat tcp-listen:${openport},reuseaddr,fork tcp:localhost:${localport} &"
}

setup_tor()
{
	socksproxy=$1
	check_apt tor

	set_conf /etc/tor/torrc
	set_conf Socks5Proxy "$socksproxy" ' '
	set_conf SOCKSPort '0.0.0.0:9050' ' '
	set_conf /etc/tor/torsocks.conf
	set_conf TorAddress '0.0.0.0'
	systemctl restart tor
}

setup_polipo()
{
	socksport=$1
	webport=$2
	check_apt polipo

	set_conf '/etc/polipo/config'
	set_conf socksParentProxy "127.0.0.1:${socksport}"
	set_conf socksProxyType socks5
	set_conf proxyAddress '::0'
	set_conf proxyPort "$webport"

	service polipo restart
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
	help_text
	exit 0
}
maintain "$@"; main "$@"; exit $?


