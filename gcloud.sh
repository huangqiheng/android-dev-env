#!/bin/dash
. $(f='basic_functions.sh'; while [ ! -f $f ]; do f="../$f"; done; readlink -f $f)
#--------------------------------------------------------------------------------#

main() 
{
	check_sudo
	check_apt gosu apt-transport-https ca-certificates gnupg

	echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" > /etc/apt/sources.list.d/google-cloud-sdk.list


	curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -

	nocmd_update gcloud
	check_apt google-cloud-sdk \
		google-cloud-sdk-bigtable-emulator \
		google-cloud-sdk-cbt \
		google-cloud-sdk-cloud-build-local \
		google-cloud-sdk-datalab \
		google-cloud-sdk-datastore-emulator \
		google-cloud-sdk-firestore-emulator \
		google-cloud-sdk-pubsub-emulator \
		kubectl

	gosu $RUN_USER gcloud init
}


#---------------------------------------------------------------------------------#
main_entry $@
