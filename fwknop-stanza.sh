#!/bin/dash

. $(dirname $(readlink -f $0))/basic_functions.sh
. $ROOT_DIR/setup_routines.sh

main () 
{
	sshHost="$1"
	targetHost=$(echo $sshHost | awk -F'@' '{print $2}')
	targetIp=$(ping -q -c 1 -t 1 $targetHost | grep PING | sed -e "s/).*//" | sed -e "s/.*(//")

	log "target ip addr: $targetIp"

	if [ "$targetIp" = "" ]; then
		log 'target host invalid'
		log 'must be ssh host: username@domain.com'
		exit
	fi

	rcfile=$UHOME/.fwknoprc
	if ! grep -q KEY $rcfile; then
		check_update
		check_apt fwknop-client fwknop-gui
		fwknop -A tcp/22 -D $targetHost --key-gen --use-hmac --save-rc-stanza
		chownUser $rcfile
	fi

	get_conf $rcfile
	KEY_BASE64=$(get_conf KEY_BASE64 ' ')
	HMAC_KEY_BASE64=$(get_conf HMAC_KEY_BASE64 ' ')

	cat > /tmp/fwknop-remote-shell.sh << EEOL
#!/bin/bash

apt install -y fwknop-server iptables-persistent

cat > /etc/fwknop/access.conf <<EOL
SOURCE                  ANY
REQUIRE_SOURCE_ADDRESS  Y
KEY_BASE64              ${KEY_BASE64}
HMAC_KEY_BASE64         ${HMAC_KEY_BASE64}
EOL

iface=\$(ifconfig | grep -B1 ${targetIp} | grep -o "^\w*")
conf="/etc/fwknop/fwknopd.conf"
if grep -qe "^PCAP_INTF" \$conf; then
	sed -ri "s|^PCAP_INTF(\s*).*;$|PCAP_INTF\1\${iface};|1" \$conf
else
	sed -ri "s|^[#; ]*PCAP_INTF(\s*).*;$|PCAP_INTF\1\${iface};|1" \$conf
fi

cat > /etc/systemd/system/fwknopd.service <<EOL
[Unit]
Description=Firewall Knock Operator Daemon
After=network-online.target

[Service]
Type=forking
ExecStart=/usr/sbin/fwknopd
ExecReload=/bin/kill -HUP \\\$MAINPID

[Install]
WantedBy=multi-user.target
EOL

systemctl enable fwknopd
systemctl start fwknopd

rm -- "\$0"
EEOL

	check_apt sshpass

	read -p "Enter password for ${sshHost}: " inputPass  
	export SSHPASS="$inputPass"

	sshpass -e scp /tmp/fwknop-remote-shell.sh $sshHost:~
	sshpass -e ssh -t $sshHost "echo $inputPass | sudo -S sh ~/fwknop-remote-shell.sh"
}

rngd()
{
	check_apt rng-tools
	rngd -r /dev/urandom
}

clean_fwknoprc_exit()
{
	rcfile=$UHOME/.fwknoprc
	unlink $rcfile
	exit
}

seal_the_ports_exit()
{
	check_sudo
	get_conf /etc/fwknop/fwknopd.conf
	iface=$(get_conf PCAP_INTF ' ')

	if [ "$1" = 'on' ]; then
		iptables -A INPUT -i $iface -p tcp --dport 22 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
		iptables -A INPUT -i $iface -p tcp --dport 22 -j DROP
	else
		iptables -D INPUT -i $iface -p tcp --dport 22 -j DROP
		iptables -D INPUT -i $iface -p tcp --dport 22 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
	fi
	exit
}

fwknopd_list_exit()
{
	check_sudo
	fwknopd --fw-list
	exit
}

maintain()
{
	[ "$1" = 'seal' ] && seal_the_ports_exit 'on'
	[ "$1" = 'unseal' ] && seal_the_ports_exit 'off'
	[ "$1" = 'list' ] && fwknopd_list_exit
	[ "$1" = 'clean' ] && clean_fwknoprc_exit $2
	[ "$1" = 'help' ] && show_help_exit $2
}

show_help_exit()
{
	cat << EOL

EOL
	exit 0
}
maintain "$@"; main "$@"; exit $?
