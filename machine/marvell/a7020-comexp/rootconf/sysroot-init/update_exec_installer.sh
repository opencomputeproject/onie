#!bin/sh

cp -f /bin/exec_installer /bin/exec_installer_edit
/bin/sed "s/tftp_wrap -g/tftp -g/g" /bin/exec_installer_edit > /bin/exec_installer
rm -f /bin/exec_installer_edit
