#!/bin/dash

. $(f='basic_functions.sh'; while [ ! -f $f ]; do f="../$f"; done; readlink -f $f)

IMG_APPS="$EXEC_NAME-apps"
SSMODE="${mode:-chnroute}"

docker_entry()
{
	gen_entrycode '###DOCKER_BEGIN###' '###DOCKER_END###'; return
	###DOCKER_BEGIN###

	TRANS_PORT=6666
	LOCAL_PORT=1080

	has_module(){ find /lib/modules/$(uname -r) -type f -name 'xt_TPROXY.ko*' >/dev/null; }
	set_conf(){ sed -ri "s|^[;# ]*${1}[ ]*=.*|${1}=${2}|" /etc/ss-tproxy/ss-tproxy.conf; }
	uncomments(){ sed -ri '/^[[:blank:]]*#/d;s/[[:blank:]]#.*//' /etc/ss-tproxy/ss-tproxy.conf; }
	waitfor_die(){ sleep infinity & CLD=$!;[ -n "$1" ] && trap "${1};kill -9 $CLD" 1 2 9 15;wait "$CLD"; }

	cat > /etc/proxychains.conf <<-EOL
		strict_chain
		proxy_dns
		tcp_read_time_out 15000
		tcp_connect_time_out 8000
		[ProxyList]
		socks5  127.0.0.1 $LOCAL_PORT
EOL

	cat > /etc/ss-tproxy/sslocal.json <<-EOF
	{
		"server":"$SSSERVER",
		"server_port":$SSPORT,
		"password":"$SSPASSWORD",
		"mode":"tcp_and_udp",
		"local_address": "127.0.0.1",
		"local_port":$LOCAL_PORT,
		"method":"xchacha20-ietf-poly1305",
		"timeout":300,
		"fast_open":false
	}
EOF
	runuser user -c 'ss-local -v -c /etc/ss-tproxy/sslocal.json &'
        PIDS2KILL="$PIDS2KILL $!"

	cat > /etc/ss-tproxy/ssredir.json <<-EOF
	{
		"server":"$SSSERVER",
		"server_port":$SSPORT,
		"password":"$SSPASSWORD",
		"mode":"tcp_and_udp",
		"local_address": "127.0.0.1",
		"local_port":$TRANS_PORT,
		"method":"xchacha20-ietf-poly1305",
		"timeout":300,
		"fast_open":false
	}
EOF
	runuser user -c 'ss-redir -c /etc/ss-tproxy/ssredir.json &'
        PIDS2KILL="$PIDS2KILL $!"

	uncomments
	[ $SSMODE = 'chnroute' ] && set_conf mode 'chnroute'
	[ $SSMODE = 'gfwlist' ] && set_conf mode 'gfwlist'
	[ $SSMODE = 'global' ] && set_conf mode 'global'
	set_conf proxy_svraddr4 "($SSSERVER)"
	set_conf proxy_svrport "$SSPORT"
	set_conf proxy_tcpport "$TRANS_PORT"
	set_conf proxy_udpport "$TRANS_PORT"
	set_conf proxy_startcmd 'true'
	set_conf proxy_stopcmd 'true'
	set_conf dnsmasq_log_enable 'true'
	set_conf chinadns_verbose 'true'
	set_conf dns2tcp_verbose 'true'
	set_conf selfonly 'true'

	proxychains ss-tproxy update-chnlist
	proxychains ss-tproxy update-gfwlist
	proxychains ss-tproxy update-chnroute
	ss-tproxy start

	cd /var/log && touch dnsmasq.log chinadns.log dns2tcp.log
	tail -f dnsmasq.log -f chinadns.log -f dns2tcp.log & 
	PIDS2KILL="$PIDS2KILL $!" 

        waitfor_die "$(cat <<-EOL
        kill $PIDS2KILL >/dev/null 2>&1
        ss-tproxy stop
        ss-tproxy flush-postrule
        ss-tproxy flush-dnscache
EOL
)"
	###DOCKER_END###
}

main() 
{
	check_sudo
	docker_home "$1" #return var: SubHome SubName

	build_image $IMG_APPS <<-EOL
	FROM phusion/baseimage:0.11
	CMD ["/sbin/my_init"]

	RUN apt update && apt install -y --no-install-recommends \
	    make gcc libc6-dev git iputils-ping curl gawk perl \
	    iproute2 iptables ipset dnsmasq dnsutils \
	    proxychains \
	    shadowsocks-libev \
	    && cd /etc && git clone https://github.com/zfl9/ss-tproxy \
	    && cd ss-tproxy && chmod +x ss-tproxy && cp -af ss-tproxy /usr/bin \
	    && cd /var/tmp && git clone https://github.com/zfl9/chinadns-ng \
	    && cd chinadns-ng && make && make install \
	    && apt purge --auto-remove -y make git gcc libc6-dev \
	    && rm -rf /tmp/* /var/tmp/* /var/lib/apt/lists/* /root/.cache/*

	RUN groupadd -r user && \ 
	    useradd -m -d /home/user -r -u 1000 -g user -G audio,video user

	ENTRYPOINT [ "/root/entrypoint" ]
EOL

	stop_dns

	docker run -it --rm \
		--net host --privileged \
		-v $SubHome:/var/log \
		-e SSSERVER=$SSSERVER \
		-e SSPORT=$SSPORT \
		-e SSPASSWORD=$SSPASSWORD \
		-e SSMODE=$SSMODE \
		-v $(docker_entry):/root/entrypoint \
		-v /etc/localtime:/etc/localtime:ro \
		--name "$EXEC_NAME-$SubName" $IMG_APPS

	resume_dns
	self_cmdline
}

stop_dns()
{
	if netstat -lnpt | grep -q 'systemd-reso'; then
		systemctl stop systemd-resolved
	fi
}

resume_dns()
{
	if ! netstat -lnpt | grep -q 'systemd-reso'; then
		systemctl start systemd-resolved
	fi
}

main_entry $@
