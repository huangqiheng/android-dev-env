#!/bin/bash

. $(f='basic_functions.sh';while [ ! -f $f ];do f="../$f";done;readlink -f $f)

CHECKOUT_DIR=unpacked
PRIVATE_DIR=private

main() 
{
	check_sudo

	if [ "$1" = 'close' ]; then
		umount_target
		exit
	fi

	checkout_target
}

git_ignore()
{
	handle_rc "$ROOT_DIR/.gitignore" "$CHECKOUT_DIR" "${CHECKOUT_DIR}/"
}

umount_target()
{
	local checkout_dir=$ROOT_DIR/$CHECKOUT_DIR
	umount $checkout_dir
}

checkout_target()
{
	local source_dir=$ROOT_DIR/$PRIVATE_DIR
	local checkout_dir=$ROOT_DIR/$CHECKOUT_DIR
	local crypt_pass=${ECRYPTFS_PASS:-default_ecrypts_pass}
	mkdir -p $source_dir
	mkdir -p $checkout_dir 

	git_ignore
	check_apt ecryptfs-utils 

	local options="no_sig_cache,ecryptfs_cipher=aes,ecryptfs_key_bytes=32,ecryptfs_passthrough=no,ecryptfs_enable_filename_crypto=yes"

	if test $crypt_pass; then
		options="$options,key=passphrase:passphrase_passwd=$crypt_pass"
	else
		read -r -p "Please input PASSWORD: " inputpass <&2
		if test $inputpass; then
			options="$options,key=passphrase:passphrase_passwd=$inputpass"
		else
			echo "Error exit, password must be set."
			return
		fi
	fi

	# echo $options
	echo "source: $source_dir"
	echo "checkout: $checkout_dir"

	umount $checkout_dir
	yes "" | mount -t ecryptfs -o $options $source_dir $checkout_dir
	chownUser $checkout_dir
}

main "$@"; exit $?
