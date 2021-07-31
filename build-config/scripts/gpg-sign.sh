#!/bin/sh

#  Copyright (C) 2021 Alex Doyle <adoyle@nvidia.com>
#  Copyright (C) 2021 Andriy Dobush <andriyd@nvidia.com>
#
#  SPDX-License-Identifier:     GPL-2.0


#
# Sign file with gpg secret key
#

GPG_SIGN_SECRING=$1
FILE=$2

usage() {
    cat <<EOF
$0: Usage
$0 <gpg secret key file> <file>

Create detached gpg signature for <file> with <gpg secret key>
EOF
}

[ -r $GPG_SIGN_SECRING ] || {
    echo "Error: secret key file is not specified"
    usage
    exit 1
}

[ -r $FILE ] || {
    echo "Error: the file to sign is not specified"
    usage
    exit 1
}

# There is a signing bug where paths over 80 characters result
# in an 'unable to load file' error on some systems - even though
# the path is totally valid.
# Check for that here, because the error is not very helpful.
GPG_DIR_LEN=$(echo $(realpath $FILE) | wc -c )
if [ $(( GPG_DIR_LEN > 80 )) = 1 ];then
    echo "ERROR!"
    echo "Directory base absolute path [ $(realpath $FILE) ] has [ $GPG_DIR_LEN ] characters."
    echo " This exceeds the 80 character limit for a gpg homedir, and will cause the"
    echo "  the gpg-agent to fail to start."
    echo " You'll get the error message: gpg: can't connect to the agent: IPC connect call failed."
    echo "Exiting."
    exit 1
else
	echo "Path to file is [ $GPG_DIR_LEN ] (less than 80)  characters. Proceeding."
fi

# Kill gpg agent to prevent sporadic gpg errors, related to running script in combination with fakeroot
if [  "$(pgrep gpg-agent )" ];then
	echo "Running $( ps waxf | grep -v grep | grep gpg-agent )"
	killall gpg-agent
fi


set -e

# Create tmp folder for new db
tmp_dir=$(mktemp -d -t gpg-XXXXXXXXXX)

GPG_KEY_ID=$(gpg --openpgp \
				 --homedir "${tmp_dir}" \
				 --import "${GPG_SIGN_SECRING}" 2>&1 | \
				 grep -m 1 "gpg: key " | \
				 sed -e 's/.*key \(.*\): .*/\1/')

echo "GPG signing $FILE with $GPG_SIGN_SECRING, key id $GPG_KEY_ID"

gpg -v --homedir ${tmp_dir} --default-key "${GPG_KEY_ID}" --yes --detach-sign --output ${FILE}.sig  ${FILE}

echo "gpg-sign.sh created detached signature $(pwd) ${FILE}.sig "

# Clear tmp folder
rm -rf $tmp_dir
