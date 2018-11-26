#!/bin/dash

. $(dirname $(readlink -f $0))/basic_functions.sh
. $THIS_DIR/setup_routines.sh

main () 
{
	check_apt python3-pip
	pip3 install https://github.com/shadowsocks/shadowsocks/archive/master.zip
	ssserver --version

	if [ $? ! -eq 0 ]; then
		log 'error install shadowssocks'
		exit 1
	fi

	mkdir -p /etc/shadowsocks
	publicIp=$(get_public_ip)

cat > /etc/shadowsocks/ss-config.json <<EOL
{
	"server":"${publicIp}",
	"local_address": "127.0.0.1",
	"local_port":1080,
	"port_password":{
		"6666":"dont-share-pass",
		"6667":"dont-share-pass",
	}
	"timeout":300,
	"method":"aes-256-cfb",
	"fast_open":false,
	"workers":1
}
EOL

	cat > /etc/systemd/system/shadowsocks.service <<EOL
[Unit]
Description=Shadowsocks Server
After=network.target

[Service]
ExecStart=/usr/local/bin/ssserver -c /etc/shadowsocks/ss-config.json
Restart=always

[Install]
WantedBy=multi-user.target
EOL
	systemctl enable shadowsocks
	systemctl start enable shadowsocks
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
