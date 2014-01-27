#!/usr/bin/python
############################################################
# <bsn.cl fy=2013 v=onl>
# 
#        Copyright 2013, 2014 BigSwitch Networks, Inc.        
# 
# Licensed under the Eclipse Public License, Version 1.0 (the
# "License"); you may not use this file except in compliance
# with the License. You may obtain a copy of the License at
# 
#        http://www.eclipse.org/legal/epl-v10.html
# 
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
# either express or implied. See the License for the specific
# language governing permissions and limitations under the
# License.
# 
# </bsn.cl>
############################################################
#
# Open Network Linux rootfs tool.
#
############################################################
import os
import sys
import argparse
import logging
import md5
import crypt
import subprocess
import fileinput
import string
import random

logging.basicConfig()
logger = logging.getLogger("rfstool");
logger.setLevel(logging.INFO)
dry=False
chroot=None

def gen_salt():
    # return an eight character salt value
    salt_map = './' + string.digits + string.ascii_uppercase + \
        string.ascii_lowercase
    rand = random.SystemRandom()
    salt = ''
    for i in range(0, 8):
        salt += salt_map[rand.randint(0, 63)]
    return salt

############################################################
#
# Log and execute
#
def cc(args, shell=False):

    if type(args) is str:
        # Must be executed through the shell
        shell=True

    if chroot:
        if type(args) is str:
            args = "chroot %s %s" % (chroot, args)
        elif type(args) in (list,tuple):
            args = ['chroot', chroot] + list(args)

    logger.info("cc:%s", args)

    if not dry:
        subprocess.check_call(args, shell=shell)


############################################################
#
# Delete a user
#
def userdel(username):
    # Can't use the userdel command because of potential uid 0 in-user problems while running ourselves
    for line in fileinput.input('/etc/passwd', inplace=True):
        if not line.startswith('%s:' % username):
            print line,
    for line in fileinput.input('/etc/shadow', inplace=True):
        if not line.startswith('%s:' % username):
            print line,

############################################################
#
# Add a user
#
def useradd(username, uid, password, shell, deleteFirst=True):
    args = [ 'useradd', '--non-unique', '--shell', shell, '--home-dir', '/root',
             '--uid', '0', '--gid', '0', '--group', 'root' ]

    if deleteFirst:
        userdel(username)

    if password:
        epassword=crypt.crypt(password, '$1$%s$' % gen_salt());
        args = args + ['-p', epassword]

    args.append(username)

    cc(args);

    if password is None:
        cc(('passwd', '-d', username))

    logger.info("user %s password %s", username, password)


############################################################
#
# Add the recovery user
#
def user_recovery_add(password):
    if password == 'standard':
        # The standard recovery password is the first eight characters
        # of the md5sum of the string 'slrecovery@[sha1]'
        sha1 = subprocess.check_output(['git', 'rev-list', 'HEAD', '-1']).strip()
        password="slrecovery@[%s]" % sha1
        logger.info("Recovery password input is '%s'", password)
        hash_=md5.new(password).hexdigest()
        logger.info("Recovery password hash is '%s'", hash_)
        password=hash_[0:8]
        logger.info("Recovery password is %s", password)

    useradd(username='recovery', uid=0, password=password,
            shell='/bin/sh')

############################################################
#
# Add the admin user
#
def user_admin_add():
    useradd(username='admin', uid=0, password=None,
            shell='/usr/bin/pcli');

############################################################
#
# Remove a user password.
#
def user_password_remove(username):
    cc('passwd -d %s' % username)

############################################################
#
# Set a user password.
#
def user_password_set(username, password):
    logger.info("user %s password now %s", username, password)
    epassword=crypt.crypt(password, '$1$%s$' % gen_salt());
    cc(['usermod', '-p', epassword, username])

############################################################
#
# Set a user shell
def user_shell_set(username, shell):
    cc('chsh --shell %s %s' % (shell, username))

############################################################
#
# Disable an user
#
def user_disable(username):
    user_shell_set(username, '/bin/false')

############################################################
#
# Overlay
#
def overlay(src, dst):
    cc('tar -C %s -c --exclude "*~" . | tar -C %s -x -v --no-same-owner' % (src, dst))

############################################################
#
# Update defaults
#
def update_rc(args):
    cc('/usr/sbin/update-rc.d %s' % (args))

def update_system_rc():
    update_rc('initdev defaults')
    update_rc('restorepersist defaults')
    update_rc('rc.boot defaults')
    update_rc('sensors-baseconf defaults')
    update_rc('loadstartupconfig defaults')
    update_rc('openbsd-inetd remove')
    update_rc('ntp remove')
    update_rc('nfs-common remove')
    update_rc('rpcbind remove')
    update_rc('motd remove')
    update_rc('kexec remove')
    update_rc('kexec-load remove')
    update_rc('mountall-bootclean.sh remove')
    update_rc('mountall.sh remove')
    update_rc('checkfs.sh remove')
    update_rc('mtab.sh remove')
    update_rc('checkroot-bootclean.sh remove')
    update_rc('checkroot.sh remove')
    update_rc('mountnfs-bootclean.sh remove')
    update_rc('mountnfs.sh remove')
    update_rc('lm-sensors remove')

def update_release_rc():
    update_rc('ofad-baseconf defaults')
    update_rc('ofad defaults')
    update_rc('snmpd-baseconf defaults')
    update_rc('snmpd remove')
    update_rc('faultd defaults')
    update_rc('ssh remove')

def update_internal_rc():
    update_rc('ofad-baseconf defaults')
    update_rc('ofad defaults')
    update_rc('snmpd-baseconf defaults')
    update_rc('snmpd remove')
    update_rc('faultd defaults')
    update_rc('ssh defaults')

def fsclean():
    with open("/etc/motd", "w") as f:
        pass
    cc('/usr/bin/apt-get clean')
    cc('/usr/sbin/localepurge')
    cc('find /usr/share/doc -type f | xargs rm -rf', shell=True)
    cc('find /usr/share/man -type f | xargs rm -rf', shell=True)


if __name__ == '__main__':

    ap = argparse.ArgumentParser(description='ONL Rootfs Configuration Tool')
    ap.add_argument('--chroot', help='Execute from workspace chroot.')
    ap.add_argument('--dry', help='Dry run only.',
                    action='store_true')
    ap.add_argument('--execute', help='Execute python call.')
    ap.add_argument('-c', help='evaluate',
                    nargs='+')

    ops = ap.parse_args()

    dry = ops.dry

    if ops.chroot:
        # The whole command must be invoked under chroot.
        chroot=ops.chroot

    if ops.execute:
        exec(ops.execute)

    if ops.c:
        f = ops.c[0]
        args = ','.join([ "'%s'" % a for a in ops.c[1:]])
        exec("%s(%s)" % (f, args))


