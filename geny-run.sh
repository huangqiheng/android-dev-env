#!/bin/dash


. $(dirname $(readlink -f $0))/basic_functions.sh
. $THIS_DIR/setup_routines.sh

main () 
{
	opt=$1
	target=$(get_target_vbox)

	if [ "$?" != 0 ]; then
		echo 'ERROR'
		exit 1
	fi

	echo "target is: $target"

	if [ "$opt" = 'close' ]; then 
		log "closing $target"
		player --vm-name "$target" -x
		exit 0
	fi

	if VBoxManage showvminfo $target| grep "State.*running"; then
		log 'Target is running, no need to start'
		exit 0
	fi

	log "starting $target"
	player --vm-name "$target"
	exit 0
}

get_target_vbox()
{
	IFS=; vmlist=$(VBoxManage list vms)
	IFS='
	'
	number=0
	for vm in $vmlist; do
		number=$(expr $number + 1)
		deviceid=$(echo $vm | awk -F\" '{print $3}' | sed 's/[ {}]//g') 
		eval "VMN_$number=$deviceid"
		echo "  $number -- $vm" >&2
	done	

	read -p "Select the index [1~$number], others for EXIT: " input
	target_device=$(eval "echo \$VMN_$input")

	if [ -z $target_device ]; then
		echo "Missign target. exit" >&2
		return 1
	fi

	echo $target_device 
	return 0
}


maintain()
{
	#check_update
	[ "$1" = 'help' ] && show_help_exit $2
}

show_help_exit()
{
	cat << EOL

EOL
	exit 0
}
maintain "$@"; main "$@"; exit $?
