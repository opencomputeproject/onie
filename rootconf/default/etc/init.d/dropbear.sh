#!/bin/sh

cmd="$1"

. /scripts/functions

name=dropbear
daemon=/usr/sbin/$name

[ -x $daemon ] || exit 0

ARGS="-m -B -P"

RSA_KEY=/etc/dropbear/dropbear_rsa_host_key
DSS_KEY=/etc/dropbear/dropbear_dss_host_key

rsa_var=onie_dropbear_rsa_host_key
dss_var=onie_dropbear_dss_host_key

# The RSA and DSS keys are stored in U-Boot environment variables.  If
# the variables are empty generate the keys and store the results for
# future boots.
get_keys() {
    # If keys are already present just return
    [ -r "$RSA_KEY" ] && [ -r "$DSS_KEY" ] && return 0

    rsa_val=$(fw_printenv -n "$rsa_var" 2> /dev/null)
    if [ -n "$rsa_val" ] ; then
        # decode base64 string
        echo "$rsa_val" | tr '@#' ' \n' | uudecode -o $RSA_KEY
    else
        # genereate rsa key
        dropbearkey -t rsa -s 1024 -f $RSA_KEY > /dev/null 2>&1
    fi

    dss_val=$(fw_printenv -n "$dss_var" 2> /dev/null)
    if [ -n "$dss_val" ] ; then
        # decode base64 string
        echo "$dss_val" | tr '@#' ' \n' | uudecode -o $DSS_KEY
    else
        # genereate dss key
        dropbearkey -t dss -s 1024 -f $DSS_KEY > /dev/null 2>&1
    fi

    if [ -z "$rsa_val" ] || [ -z "$dss_val" ] ; then
        tmp_env=$(mktemp)
        # encode key values
        if [ -z "$rsa_val" ] ; then
            rsa_val=$(uuencode -m $RSA_KEY r | tr ' \n' '@#')
            echo "$rsa_var $rsa_val" >> $tmp_env
        fi
        if [ -z "$dss_val" ] ; then
            dss_val=$(uuencode -m $DSS_KEY d | tr ' \n' '@#')
            echo "$dss_var $dss_val" >> $tmp_env
        fi
        fw_setenv -f -s $tmp_env || {
            log_failure_msg "Unable to save dropbear ssh server keys"
        }            
        rm -f $tmp_env
    fi
}

case $cmd in
    start)
        killall $name > /dev/null 2>&1
        log_begin_msg "Starting: $name ssh daemon"
        get_keys || exit 1
        cd / && $daemon $ARGS
        log_end_msg
        ;;
    stop)
        log_begin_msg "Stopping: $name ssh daemon"
        killall $name > /dev/null 2>&1
        log_end_msg
        ;;
    *)
        
esac
