
#!/bin/bash

. $(dirname $(readlink -f $0))/basic_functions.sh

LISTEN_PORT=2018

main () 
{
	cd $ROOT_DIR && mkdir -p temp && cd temp

	wget --no-check-certificate https://raw.github.com/Lozy/danted/master/install_centos.sh -O install.sh 
	bash install.sh --port=${LISTEN_PORT}

	cat << EOL
service sockd start	start socks5 server daemon
service sockd stop	stop socks5 server daemon
service sockd restart	restart socks5 server daemon
service sockd reload	reload socks5 server daemon
service sockd restart	restart socks5 server daemon
service sockd status	systemd process status
service sockd state	state	running state
service sockd tail	sock log tail
service sockd adduser	add pam-auth user: service sockd adduser NAME PASSWORD
service sockd deluser	delete pam-auth user: service sockd deluser NAME
EOL

}
