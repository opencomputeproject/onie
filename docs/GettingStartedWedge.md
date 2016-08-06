Getting Started With the Accton Wedge
------------------------------------------------
To install and run ONL on the Accton Wedge you will need ONIE and 
the ONL wedge installer binary. Relevant pointers can be found at
https://opennetlinux.org/wedge

Once installed, ONL has a default account ("root") with a default password 
("onl").  The network interface is disabled by default so that you can change 
the root password before the system comes up.  You will need to enable the
network interface before you can run the FBOSS agent.

FBOSS is installed and set to run the configuration created for a OCP ONL
on Wedge Demo.  This configuration sets up the first physical QSFP port of 
the wedge as 4 10G ports (via a break out cable) and configures vlans and 
ip addresses on them.

ONIE Manual Install
------------------------------------------------
If your Accton Wedge does not have ONIE installed, you will need to install
it before you can proceed.

1) Download the ONIE rescue image from http://opennetlinux.org/binaries/accton-wedge/onie-recovery-x86_64-accton_wedge_16x-r0.iso

2) Burn the image onto a USB (a USB with a minimum size of 256M is necessary)

3) Insert the USB into the front USB port on the Wedge

4) Attach a serial terminal to the wedge

5) Power on the wedge and wait for the BMC to finish booting

6) Log into the bmc with the login: root password: 0penBmc

7) Attach to the wedge microserver using the command sol.sh

8) If the microserver shows the BIOS status screen press F2 to go to the BIOS 
configuration menu

9) In cases where the wedge microserver has already booted into the default 
linux installation, you will need to either reboot (if possible) or hit ctrl-x, exiting to the BMC and issue the "wedge_power reset" command to power-cycle the
microserver, run sol.sh again and hit F2 when the BIOS status screen appears

10) One you are in the BIOS configuration, move to the boot screen and change
the boot mode from UEFI to Legacy

11) In the boot device list, make sure that the USB is set to #1

12) Hit esc-0 to or F10 to save and exit the configuration

13) The system will now boot from the ONIE rescue USB

14) When the ONIE Grub window appears, choose "Embed ONIE"

15) ONIE will be installed on the system and the system will automatically
reboot

16) *IMPORTANT* Remove the USB from the system before proceeding to the ONL install

ONL Manual Install
------------------------------------------------
1) Attach a serial terminal to the wedge

2) Boot switch and choose "ONIE: Rescue" to go to ONIE''s interactive mode

3) From the ONIE# prompt run "install_url http://opennetlinux.org/binaries/latest-wedge.installer"

4) Wait for the install to finish and the system to reboot

5) One the onl login prompt appears login with the username root and the
password "onl"

6) You can now change the root password

7) Configure the ma1 interface either via dhcp (dhclient ma1) or manually

8) From the command prompt you can start fboss by using the command 
"service fboss_wedge_agent start"

9) The first time you start the fboss_wedge_agent service it will download 
the OpenNSL library from the Broadcom github account.

10) Once the library is installed, fboss_wedge_agent will start, using the
default configuration located at /etc/fboss/ocp-demo.json

11) You can confirm that the fboss_wedge_agent is running by issuing the
command "service fboss_wedge_agent status"

12) If fboss is running, you should see "[ ok ] fboss_wedge_agent is running."

13) You can now execute the fboss_route.py script and configure the system.

Modifying The fboss_wedge_agent configuration
------------------------------------------------
In the /etc/init.d/fboss_wedge_agent script, you will locate a section where
the configuration file "FBOSS_DAEMON_OPTIONS" is set:

OCP_DEMO="-config /etc/fboss/ocp-demo.json"
SAMPLE1="-config /etc/fboss/sample1.json"
SAMPLE2="-config /etc/fboss/sample2.json"
SAMPLE3="-config /etc/fboss/sample3.json"
FBOSS_DAEMON_OPTIONS=$OCP_DEMO

The sample configurations are documented here: https://github.com/facebook/fboss/tree/master/fboss/agent/configs

To change the configuration, simply change the variable from $OCP_DEMO to $SAMPLE1/2/3 or add your own configuration and set the variable to call it.


Expected output (you can also see videos at https://opennetlinux.org/wedge)

ONIE:
                     
        ONIE: Using DHCPv4 addr: eth0: 10.7.1.10 / 255.254.0.0
        discover: installer mode detected.  Running installer.

        Please press Enter to activate this console. ONIE: Using DHCPv4 addr: eth0: 10.7.1.10 / 255.254.0.0
        ONIE: Starting ONIE Service Discovery

        To check the install status inspect /var/log/onie.log.
        Try this:  tail -f /var/log/onie.log

Now press RETURN here to jump into ONIE''s manual installer mode.  You should see:

        ** Installer Mode Enabled **

        ONIE:/ # 

Then simply download the latest ONL wedge installer from the website and run it.

        ONIE:/ # install_url http://opennetlinux.org/binaries/latest-wedge.installer

        Connecting to opennetlinux.org (107.170.237.53:80)
        Open Network Installer running under ONIE.
        Installer Version: Open Network Linux 019421c (amd64.all,2015.11.17.06.23,019421c116940d87d5a41100d1b8a64cbba50252)
        Detected platform: x86-64-accton-wedge-16x-r0
        Installing in standalone mode.
        Unpacking Open Network Linux installer files...
        ...

        Connecting tty=ttyS1 with /sbin/pgetty

        Open Network Linux  019421c (amd64.all,2015.11.17.06.23,019421c116940d87d5a41100d1b8a64cbba50252)

        onl-wedge login:

