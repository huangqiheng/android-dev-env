#!/bin/dash

. $(dirname $(readlink -f $0))/basic_functions.sh
. $THIS_DIR/setup_routines.sh

main () 
{
	sshhost_parse "$1"
	check_apt gpg sshpass

	GPG_gen_key_local
	GPG_gen_key_remote



}

GPG_gen_key_remote()
{

}

GPG_node_parse()
{
}

GPG_gen_key_local()
{
###-GEN PGP KEY BEGIN-###
	local hostUserId="ANDNode.Server.$(cat /etc/machine-id)"
	local passphrase=$(echo "$hostUserId@md5sum.stupid" | md5sum | awk '{print $1}')
	local userid=$(GPG_get_userid $hostUserId)

	if [ "$userid" = "" ]; then
		cat >/tmp/foo <<EOF
%echo Generating a standard key
Key-Type: default 
Subkey-Type: default
Name-Real: $hostUserId
Name-Comment: fwknopd node
Name-Email: oh@my.god
Expire-Date: 0
Passphrase: $passphrase
%commit
%echo done
EOF
		gpg --batch --gen-key /tmp/foo
		rm -f /tmp/foo

		GPG_get_userid $hostUserId
		return
	fi
	echo $userid

###-GEN PGP KEY END-###
}

clean_exit()
{
	local hostUserId="ANDNode.Server.$(cat /etc/machine-id)"
	local userid=$(GPG_get_userid $hostUserId)
	if [ "$userid" = "" ]; then
		exit 1
	fi

	gpg --batch --yes --delete-secret-and-public-key $userid
	exit 0
}

GPG_list_names()
{
	gpg --list-keys  | grep uid |  tr -d "[]<>" | awk '{print $3}'
}

GPG_get_userid()
{
	gpg --list-keys "$1" 2>/dev/null | sed -n 2p | tr -d ' '
}

maintain()
{
	[ "$1" = 'clean' ] && clean_exit
	[ "$1" = 'help' ] && show_help_exit $2
	check_update
}

show_help_exit()
{
	cat << EOL

EOL
	exit 0
}
maintain "$@"; main "$@"; exit $?
