#!/bin/dash

. $(dirname $(readlink -f $0))/basic_functions.sh
. $ROOT_DIR/setup_routines.sh

main () 
{
	check_apt gpg sshpass

	GPG_gen_key_remote $*


}

#-- ssh_remote_exec 'apt|repo' (apt apt2 apt3 apt4'|repo1 repo2 repo3)
#-- ssh_remote_exec '^##BEGIN-BLOCK' '^##END-BLOCK' ['/path/to/self/script']
#-- ssh_remote_exec 'ssh@host.name[:22]'

ssh_remote_run()
{
	[ $# -eq 0 ] && return

	if [ "$SSHREMOTE_script" = '' ]; then
		SSHREMOTE_script="#!/bin/dash\n"
	fi

	if echo "$1" | grep -q "apt\|repo"; then
		local opt="$1"
		local arg_begin=$((${#1}+1))
		IFS=' '; set -- $(echo "$*" | cut -c ${arg_begin}- | sed 's/^[ \t]*//;s/[ \t]*$//')

		for package; do
			if [ "$opt" = 'apt' ]; then
				SSHREMOTE_script="${SSHREMOTE_script}apt install -y ${package}\n"
			else
				SSHREMOTE_script="${SSHREMOTE_script}add-apt-repository -y ${package}\n"
			fi
		done

		if [ "$opt" = 'repo' ]; then
			SSHREMOTE_script="${SSHREMOTE_script}apt update -y\n"
		fi

		echo $SSHREMOTE_script

		return 0
	fi

	if [ $# -eq 1 ]; then
		IFS='@:'; set -- $(echo "$1")
		local sshUser="$1"
		local sshHost="$2"
		local sshPort=${3:-'22'}
		local sshAddr=$(ping -q -c 1 -t 1 $sshHost 2>/dev/null | grep PING | sed -e "s/).*//;s/.*(//")

		if [ "$sshAddr" = '' ]; then
			log_red "ERR: the input ip addr invalid."
			exit 1
		fi

		local end_str="\nrm -- \"\$0\""
		SSHREMOTE_script="${SSHREMOTE_script}\n$end_str"


		#tar cz a/dir | pv | ssh remotehost "cat >outfile.tar.gz"


		return 0
	fi

	local Mark_Begin="$1"; 
	local Mark_End="$2"
	local this_script=$(readlink -f $0)
	local Mark_file="${3:-$this_script}"

	if [ ${Mark_Begin%"${Mark_Begin#?}"} != '#' ] || [ ${Mark_End%"${Mark_End#?}"} != '#' ]; then
		log_red "ERR: the input tag format invalid."
		exit 1
	fi

	local lineBegin=$(awk "/^${Mark_Begin}/{print NR; exit}" $Mark_file)
	local lineEnd=$(awk "/^${Mark_End}/{print NR; exit}" $Mark_file)
	IFS=; script=$(sed -n "${lineBegin},${lineEnd}p" $Mark_file)

	SSHREMOTE_script="${SSHREMOTE_script}\n${script}\n"
}

GPG_gen_key_remote()
{
	ssh_target="$1"
	ssh_remote_run apt gpg
	ssh_remote_run '###-GEN-GPG-KEY-BEGIN' '###-GEN-GPG-KEY-END'
	ssh_remote_run $ssh_target
}

GPG_gen_key_local()
{
###-GEN-GPG-KEY-BEGIN-###
	local hostUserId="ANDNode.Server.$(cat /etc/machine-id)"
	local passphrase=$(echo "$hostUserId@md5sum.stupid" | md5sum | awk '{print $1}')
	local userid=$(gpg --list-secret-keys "$hostUserId" 2>/dev/null | sed -n 2p | tr -d ' ')
	local pubkey="/tmp/ANDNode-Server-Pubkey.asc"

	if [ "$userid" = "" ]; then
		cat > /tmp/${hostUserId}.bat <<EOF
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
