#!/bin/bash
target_server='rpms.litespeedtech.club'
source ./functions.sh #2>/dev/null
echo " Check if the user is root "
if [ $(id -u) != "0" ]; then
    echo "Error: The user is not root "
    echo "Please run this script as root"
    exit 1
fi

product=$1
dists=$2
input_archs=$3
build_flag=$4
release_flag=$5
version="grep ${product} VERSION.txt | awk -F '=' '{print $2}'"
revision=$(curl -isk https://${target_server}/debian/pool/main/$dists/ | grep ${product}_${version} \
  | awk -F '-' '{print $4}' | awk -F '+' '{print $1}' | tail -1)
if [ $revision == ?(-)+([[:digit:]]) ]; then
    revision=$((revision+1))
else
    revision=1
fi
lsapi_version=8.1
#if [ $dists = "ALL" ]; then
#        echo " convert dists value "
#            dists="jammy bionic buster focal bullseye bookworm noble"
#        echo " the new value for dists is $dists "
#fi

if [ $input_archs = "ALL" ]; then
    echo " convert archs value "
    archs="amd64 arm64"
    echo " the new value for archs is $archs "
else
    archs=$input_archs
fi

check_input
set_paras
set_build_dir
prepare_source
pbuild_packages
echo "##################################################"
echo " The package building process has finished ! "
echo "##################################################"
echo "########### Build Result Content #################"

for dist in $dists; do
    ls -lR $BUILD_RESULT_DIR/$dist;
done

echo " ################# End of Result #################"
echo $(date)

ls -lR $BUILD_RESULT_DIR/$dist | grep ${product}_${version}-${revision}+${dists}_.*.deb >/dev/null
if [ ${?} != 0 ] ; then
    echo "${product}_${version}-${revision}+${dists}_.*.deb is not found!"
    exit 1
else
    upload_to_server
fi

if [ "$release_flag" == 'yes' ]; then
        sign_release
fi