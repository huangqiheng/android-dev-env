#!/bin/dash

. $(dirname $(readlink -f $0))/basic_functions.sh
. $THIS_DIR/setup_routines.sh

main () 
{
	install_ssredir

	check_apt dnsmasq
	check_apt ipset iproute2 perl curl
	install_chinadns

	install_tproxy


}

install_ssredir()
{
	if  cmd_exists 'ss-redir'; then
		log_y 'ss-redir is ready'
		return
	fi

	check_apt haveged rng-tools shadowsocks-libev

	cat > /etc/shadowsocks-libev/multi-user.json <<EOL
{
        "server":"",
        "password":"",
        "mode":"tcp_and_udp",
        "server_port":16666,
        "local_address": "0.0.0.0",
        "local_port":6666,
        "method":"xchacha20-ietf-poly1305",
        "timeout":300,
        "fast_open":false
}
EOL

	systemctl enable shadowsocks-libev-redir@.service
	systemctl daemon-reload
	systemctl start shadowsocks-libev-redir@multi-user.service
}

install_tproxy()
{
	if  cmd_exists 'ss-tproxy'; then
		log_y 'ss-tproxy is ready'
		return
	fi

	cd $CACHE_DIR
	git clone https://github.com/zfl9/ss-tproxy
	cd ss-tproxy
	cp -af ss-tproxy /usr/local/bin
	chmod 0755 /usr/local/bin/ss-tproxy
	chown root:root /usr/local/bin/ss-tproxy
	mkdir -m 0755 -p /etc/ss-tproxy
	cp -af ss-tproxy.conf gfwlist.* chnroute.* /etc/ss-tproxy
	chmod 0644 /etc/ss-tproxy/* && chown -R root:root /etc/ss-tproxy

	cp -af ss-tproxy.service /etc/systemd/system
	systemctl daemon-reload
	systemctl enable ss-tproxy.service
}

remove_tproxy()
{
	ss-tproxy stop
	ss-tproxy flush-iptables
	rm -fr /etc/ss-tproxy /usr/local/bin/ss-tproxy
}

install_chinadns()
{
	if  cmd_exists 'chinadns'; then
		log_y 'chinadns is ready'
		return
	fi

	local chinadns=chinadns-1.3.2
	cd $CACHE_DIR
	if [ ! -f ${chinadns}.tar.gz ]; then
		wget https://github.com/shadowsocks/ChinaDNS/releases/download/1.3.2/${chinadns}.tar.gz
	fi
	tar xf ${chinadns}.tar.gz
	cd ${chinadns}
	./configure
	make && make install
}

maintain()
{
	check_update
	[ "$1" = 'help' ] && show_help_exit
	[ "$1" = 'remove' ] && remove_tproxy && exit 0
}

show_help_exit()
{
	cat << EOL
	help
	sudo sh ss-tproxy.sh remove
EOL
	exit 0
}

maintain "$@"; main "$@"; exit $?
