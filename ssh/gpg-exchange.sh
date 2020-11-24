#!/bin/dash

. $(dirname $(readlink -f $0))/basic_functions.sh
. $ROOT_DIR/setup_routines.sh

main () 
{
	check_apt gpg sshpass
	GPG_gen_key_remote $*
}

GPG_gen_key_remote()
{
	ssh_target="$1"
	ssh_remote_run apt gpg
	ssh_remote_run '###-GEN-GPG-KEY-BEGIN' '###-GEN-GPG-KEY-END'
	ssh_remote_run $ssh_target
	return $?

###-GEN-GPG-KEY-BEGIN-###
	local hostUserId="ANDNode.Server.$(cat /etc/machine-id)"
	local passphrase=$(echo "$hostUserId@md5sum.stupid" | md5sum | awk '{print $1}')
	local userid=$(gpg --list-secret-keys "$hostUserId" 2>/dev/null | sed -n 2p | tr -d ' ')
	local pubkey="/tmp/ANDNode-Server-Pubkey.asc"

	if [ "$userid" = "" ]; then
		cat > /tmp/${hostUserId}.bat <<-EOF
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
		gpg --batch --gen-key /tmp/${hostUserId}.bat
		rm -f /tmp/${hostUserId}.bat

		userid=$(gpg --list-secret-keys "$hostUserId" 2>/dev/null | sed -n 2p | tr -d ' ')
	fi

	gpg -a --export $userid --output $pubkey
###-GEN-GPG-KEY-END-###
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
