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

if [ -z "${version}" ]; then
    version="$(grep ${product}= VERSION.txt | awk -F '=' '{print $2}')"
fi
if [ -z "${revision}" ]; then
    revision=$(curl -isk https://${target_server}/debian/pool/main/$dists/ | grep ${product}_${version} \
      | awk -F '-' '{print $4}' | awk -F '+' '{print $1}' | tail -1)
    if [[ $revision == ?(-)+([[:digit:]]) ]]; then
        revision=$((revision+1))
    else
        echo "$revision is not a number, set value to 1"
        revision=1
    fi      
fi      

lsapi_version=8.1
if [ $dists = "all" ]; then
        echo " convert dists value "
            dists="jammy noble"
            #dists="jammy bionic buster focal bullseye bookworm noble"
        echo " the new value for dists is $dists "
fi

archs=$input_archs

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

for dist in $dists; do
    ls -lR $BUILD_RESULT_DIR/$dist | grep ${product}_${version}-${revision}+${dist}_.*.deb >/dev/null
    if [ ${?} != 0 ] ; then
        echo "${product}_${version}-${revision}+${dist}_.*.deb is not found!"
        exit 1   
    fi
done

upload_to_server
if [ "$release_flag" == 'yes' ]; then
        sign_release
fi
echo $(date)