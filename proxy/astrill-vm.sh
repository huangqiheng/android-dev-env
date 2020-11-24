#!/bin/bash

. $(dirname $(dirname $(readlink -f $0)))/basic_functions.sh
. $ROOT_DIR/setup_routines.sh

main () 
{
	cloudinit_remove
	auto_login
	auto_startx

	if [ ! -f $UHOME/sslocal.json ]; then
		log 'Please prepare the sslocal.json file'
		exit 1
	fi

	check_update universe
	check_apt xinit ratpoison 

	# install astrill
	install_astrill
	check_apt xvfb
	ratpoisonrc "exec Xvfb :1 -screen 0 1920x1080x24 -fbdir /var/tmp &"
	ratpoisonrc "exec DISPLAY=:1 /usr/local/Astrill/astrill"
	setup_socat 3213 3128

	# install sslocal
	setup_sslocal
	setup_polipo 7070 8213

	# install tor
	setup_tor '127.0.0.1:7070'

	# others, for test
	ratpoisonrc_done
	check_apt proxychains 
	x11_forward_server
	help_text
	apt autoremove
}

setup_sslocal()
{
	check_apt shadowsocks 

	cat > /etc/systemd/system/sslocal.service <<EOL
[Unit]
Description=Sslocal Server
After=network.target

[Service]
ExecStart=/usr/bin/sslocal -c ${UHOME}/sslocal.json
Restart=always

[Install]
WantedBy=multi-user.target
EOL
	systemctl enable sslocal
	systemctl start enable sslocal
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


