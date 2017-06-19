#!/bin/bash

THIS_DIR=`dirname $(readlink -f $0)`
. $THIS_DIR/config.sh

user=$(git config --global --get user.name)
[ -z $user ] && git config --global --set user.name $USER_NAME

email=$(git config --global --get user.email)
[ -z $email ] && git config --global --set user.email $USER_EMAIL

push=$(git config --global --get push.default)
[ -z $push ] && git config --global --set push.default $PUSH_DEFAULT

push_url=$(git remote get-url --push origin)

if ! echo $push_url | grep -q "$PUSH_USER"; then
	new_url=$(echo $push_url | sed -e "s/\/\//\/\/${PUSH_USER}:@/g")
	git remote set-url origin $new_url
	echo "update remote url: $new_url"
fi

cd $THIS_DIR
git add .
git commit -m "update"
git push

