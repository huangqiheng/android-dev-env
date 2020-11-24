#!/bin/dash

. $(dirname $(readlink -f $0))/basic_functions.sh
. $ROOT_DIR/setup_routines.sh

main () 
{
	check_apt shadowsocks

	read -p "Please input Shadowsocks server: " inputServer 

	if [ -z "$inputServer" ]; then
		log 'inputed server error'
		exit 1
	fi

	read -p "Input PASSWORD: " inputPass

	if [ -z "$inputPass" ]; then
		log 'pasword must be set'
		exit 2
	fi

	cat > /etc/shadowsocks/sslocal.json <<EOL
{
	"server":"${inputServer}",
	"local_address": "0.0.0.0",
	"local_port":1080,
	"password":"${inputPass}",
	"timeout":300,
	"method":"aes-256-cfb"
}
EOL

	cat > /lib/systemd/system/sslocal.service <<EOL
[Unit]
Description=Sslocal Server
After=network.target

[Service]
ExecStart=/usr/bin/sslocal -c /etc/shadowsocks/sslocal.json
Restart=always

[Install]
WantedBy=multi-user.target
EOL

	systemctl enable sslocal
	systemctl start sslocal

	log 'Now Socks5 listen on 0.0.0.0:1080'
}

maintain()
{
	check_update
	[ "$1" = 'help' ] && show_help_exit $2
}

show_help_exit()
{
	cat << EOL

EOL
	exit 0
}
maintain "$@"; main "$@"; exit $?
