#!/bin/bash

. $(dirname $(readlink -f $0))/basic_functions.sh

GIT_USER_NAME=$RUN_USER
GIT_USER_EMAIL="${GIT_USER_NAME}@github.com"

! cmd_exists git && apt install -y git
! cmd_exists vim && apt install -y vim

repo_update
