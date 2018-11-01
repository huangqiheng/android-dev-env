#!/bin/bash

#---------------------------------------------------------------------
# pull

THIS_DIR=`dirname $(readlink -f $0)`

cd $THIS_DIR
IFS=; pull_result=$(git pull)

if echo $pull_result | grep -q 'insufficient permission for adding an object'; then
	sudo chown -R $(id -u):$(id -g) "$(git rev-parse --show-toplevel)/.git"
fi

if echo $pull_result | grep -q 'use "git push" to publish your local commits'; then
	git push
	exit
fi
echo $pull_result

#---------------------------------------------------------------------
# config

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
	echo "Update remote url: $new_url"
fi

#---------------------------------------------------------------------
# push

input_msg=$1
input_msg=${input_msg:="update"}

cd $THIS_DIR
git add .
IFS=; commit_result=$(git commit -m "${input_msg}")

if echo $commit_result | grep -q 'nothing to commit'; then
	echo 'Nothing to commit.'
	exit
fi

echo $commit_result

git config --global credential.helper 'cache --timeout 21600'
git push

