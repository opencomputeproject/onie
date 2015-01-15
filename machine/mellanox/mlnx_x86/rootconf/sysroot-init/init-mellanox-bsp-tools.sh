#! /bin/sh

# Copyright (C) 2015 Mellanox Technologies, Ltd. All rights reserved.

# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:

# Redistributions of source code must retain the above copyright notice,
# this list of conditions and the following disclaimer.
# Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation
# and/or other materials provided with the distribution.

# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.

. /lib/onie/functions

current_action=$1

mellanox_init_module="Mellanox bsp tools"

is_lpci2c_loaded() {
    lsmod | grep lpci2c 1>/dev/null
}

init_system() {
    if is_lpci2c_loaded ; then
        log_info_msg "lpci2c module has already been loaded"
    else
        modprobe lpci2c
    fi
}

deinit_system() {
    if is_lpci2c_loaded ; then
        rmmod lpci2c || log_warning_msg "rmmod lpci2c failed"
    else
        log_info_msg "No lpci2c module loaded"
    fi
}

case ${current_action} in
    start)
        log_begin_msg "Starting: ${mellanox_init_module}"
        init_system
        log_end_msg
        exit 0
        ;;
    stop)
        log_begin_msg "Stopping: ${mellanox_init_module}"
        deinit_system
        log_end_msg
        exit 0
        ;;
    *)
        log_failure_msg "Usage: $0 <start|stop>"
        exit 1
        ;;
esac
