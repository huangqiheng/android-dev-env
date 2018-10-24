#!/bin/bash

THIS_DIR=`dirname $(readlink -f $0)`
. $THIS_DIR/config.sh
GIT_PUSH_DEFAULT=simple

user=$(git config --global --get user.name)
[ -z $user ] && git config --global --add user.name $GIT_USER_NAME

email=$(git config --global --get user.email)
[ -z $email ] && git config --global --add user.email $GIT_USER_EMAIL

push=$(git config --global --get push.default)
[ -z $push ] && git config --global --add push.default $GIT_PUSH_DEFAULT

push_url=$(git remote get-url --push origin)

if ! echo $push_url | grep -q "${GIT_PUSH_USER}@"; then
	new_url=$(echo $push_url | sed -e "s/\/\//\/\/${GIT_PUSH_USER}@/g")
	git remote set-url origin $new_url
	echo "update remote url: $new_url"
fi

input_msg=$1
input_msg=${input_msg:="update"}

cd $THIS_DIR

git pull

git add .
commit_result=$(git commit -m "${input_msg}")

echo $commit_result
if echo $commit_result | grep 'nothing to commit'; then
	exit
fi

git push

