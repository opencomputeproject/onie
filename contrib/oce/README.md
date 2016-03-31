# OCE (ONIE Compliance Environment)

This directory represents all the tools that are used for
* Automated ONIE Builds (via CI tools like Jenkins)
* Automated ONIE Testing using the same tools found in deployments

## Building ONIE

Traditionally, to build an ONIE machine image, the user would
```
# cd ONIE/build-config
make MACHINEROOT=../machine/accton MACHINE=accton_as5712_54x all
```

While this would build only one ONIE image, we needed a way to simplify this
process to build multiple machine images at a given time.

### build-onie.py

```build-onie.py``` allows the user to view all vendors / machine targets
available for building along with providing an easy way to build them.

To build all machine images from a given vendor:

```# ./build-onie.py -b accton```

To build all machine images from a given vendor and an additional machine:

```# ./build-onie.py -b quanta -b accton_as5712_54x```

Take a look at the help for ```build-onie.py``` to see the additional options.

## Testing ONIE

Testing ONIE from a user's perspective included naming the NOS
installer ```onie-installer```, placing it in the root location of a web server,
and letting ONIE do it's thing.  While this works, it doesn't fully test a
vendor's implementation of ONIE:
* proper HTTP Headers
* DHCP options
* Proper ONIE image discovery
* The rest of the ONIE feature set
    * Self Update
    * Rescue
    * Uninstallation of a NOS

While most of these actions can be observed and recorded by the user, it is
typically not their deployment strategy to do so.  As such, we have a simpler
way of doing so for certification labs, vendors, and others to use the same
deployment tools that an end user will use to provide a suite of tests to ensure
a HW vendor's implementation of ONIE is compliant with the OCP specification.

### test-onie.py

```test-onie.py``` allows the automatic configuration and testing of a given
test from the OCP ONIE specification.

It takes a list of arguments:
* MAC address of the DUT (Device Under Test)
* IP address (in CIDR form) of the DUT
* test number
   * For NOS installs, a NOS image
   * For ONIE self update, an ONIE image

And ```test-onie.py``` takes care of the rest.  By default, ```test-onie.py```
uses the following:
* DHCP using isc-dhcp-server
* DNS using dnsmasq
* TFTP using tftpd-hpa
* HTTP using nginx

However, it is possible to change out the back end services by either modifying
the test definition file (default: config/onie-tests.json) or creating a new
one.

Before we get started, if your system is running ```apparmor```, you must stop it and unload all the profiles.  Typically, this involves:
```
# sudo service apparmor stop
# sudo service apparmor teardown
```

To use ```test-onie.py```, you need to have all of the python modules, defined
in ```requirements.txt``` installed.

An easy way to do this is to use python's virtualenv.

Ensure you have ```pip``` and ```virtualenv``` installed.
```
# sudo apt-get install python-pip python-virtualenv
```

Then create the virtual environment.
```
# virtualenv .venv
```

Now let's enter the virtual environment and install our dependencies
```
# source .venv/bin/activate
(.venv) # pip install -r requirements.txt
```

Now you are ready to run ```test-onie.py```.

To get a listing of what ```test-onie.py``` is expecting, use the ```-h``` flag.
```
usage: test-onie.py [-h] [-c CONFIG] [-d CONFIG] [-D] [-i CIDR] [-I INTERFACE]
                    [-l] [-m MAC] [--disable-checks] [-t TEST NUM] [-v]
                    [-o KEY VALUE [KEY VALUE ...]] [-O DIR]

Test ONIE

optional arguments:
  -h, --help            show this help message and exit
  -c CONFIG, --config CONFIG
                        ONIE test definitions
  -d CONFIG, --dut-config CONFIG
                        DUT configuration file
  -D, --dump            Dump configs and scripts but do not execute
  -i CIDR, --ip-cidr CIDR
                        IP Address in CIDR format for DUT
  -I INTERFACE, --interface INTERFACE
                        Interface to bind against
  -l, --list            list all tests
  -m MAC, --mac-address MAC
                        MAC address of DUT
  --disable-checks      Disable all Network checks. Useful when running on
                        another machine.
  -t TEST NUM, --test TEST NUM
                        ONIE test number to execute
  -v, --verbose         increase the verbosity level
  -o KEY VALUE [KEY VALUE ...], --option KEY VALUE [KEY VALUE ...]
                        Set additional options, space separated. Current
                        options are: [dhcp_binary dhcp_dns_server
                        dhcp_domain_name dhcp_gateway dhcp_group
                        dhcp_lease_time dhcp_max_lease_time dhcp_next_server
                        dhcp_user http_binary http_group http_port http_user
                        onie_arch onie_installer onie_machine onie_machine_rev
                        onie_updater onie_vendor tftp_binary tftp_group
                        tftp_user]
  -O DIR, --output-dir DIR
                        output director (default: output)
```

To see what are all the possible test cases, use the ```-l``` option.
```
# ./test-onie.py -l
2015-01-16T12:16:09 - INFO - Loaded 80 tests from config/onie-tests.json
Test 0 => Cold Boot
Test 1 => Warm Boot
Test 2 => Static Loader
Test 3 => USB - Name 1
Test 4 => USB - Name 2
Test 5 => USB - Name 3
Test 6 => USB - Name 4
Test 7 => USB - Name 5
Test 8 => DHCP Exact - VIVSO
Test 9 => DHCP Exact - Default URL
Test 10 => DHCP Exact - TFTP Server IP + TFTP Bootfile
Test 11 => DHCP Exact - TFTP Server name + TFTP Bootfile
Test 12 => DHCP Inexact - TFTP Bootfile
Test 13 => DHCP Inexact - HTTP Server IP - Name 1
Test 14 => DHCP Inexact - HTTP Server IP - Name 2
Test 15 => DHCP Inexact - HTTP Server IP - Name 3
Test 16 => DHCP Inexact - HTTP Server IP - Name 4
Test 17 => DHCP Inexact - HTTP Server IP - Name 5
Test 18 => DHCP Inexact - TFTP Server IP - Name 1
Test 19 => DHCP Inexact - TFTP Server IP - Name 2
Test 20 => DHCP Inexact - TFTP Server IP - Name 3
Test 21 => DHCP Inexact - TFTP Server IP - Name 4
Test 22 => DHCP Inexact - TFTP Server IP - Name 5
Test 23 => DHCP Inexact - DHCP Server IP - Name 1
Test 24 => DHCP Inexact - DHCP Server IP - Name 2
Test 25 => DHCP Inexact - DHCP Server IP - Name 3
Test 26 => DHCP Inexact - DHCP Server IP - Name 4
Test 27 => DHCP Inexact - DHCP Server IP - Name 5
Test 28 => IPv6 Neighbor - Name 1
Test 29 => IPv6 Neighbor - Name 2
Test 30 => IPv6 Neighbor - Name 3
Test 31 => IPv6 Neighbor - Name 4
Test 32 => IPv6 Neighbor - Name 5
Test 33 => TFTP Waterfall - Name 1
Test 34 => TFTP Waterfall - Name 2
Test 35 => TFTP Waterfall - Name 3
Test 36 => TFTP Waterfall - Name 4
Test 37 => TFTP Waterfall - Name 5
Test 38 => ONIE Update - Static Loader
Test 39 => ONIE Update - USB - Name 1
Test 40 => ONIE Update - USB - Name 2
Test 41 => ONIE Update - USB - Name 3
Test 42 => ONIE Update - USB - Name 4
Test 43 => ONIE Update - USB - Name 5
Test 44 => ONIE Update - DHCP Exact - VIVSO
Test 45 => ONIE Update - DHCP Exact - Default URL
Test 46 => ONIE Update - DHCP Exact - TFTP Server IP + TFTP Bootfile
Test 47 => ONIE Update - DHCP Exact - TFTP Server name + TFTP Bootfile
Test 48 => ONIE Update - DHCP Inexact - TFTP Bootfile
Test 49 => ONIE Update - DHCP Inexact - HTTP Server IP - Name 1
Test 50 => ONIE Update - DHCP Inexact - HTTP Server IP - Name 2
Test 51 => ONIE Update - DHCP Inexact - HTTP Server IP - Name 3
Test 52 => ONIE Update - DHCP Inexact - HTTP Server IP - Name 4
Test 53 => ONIE Update - DHCP Inexact - HTTP Server IP - Name 5
Test 54 => ONIE Update - DHCP Inexact - TFTP Server IP - Name 1
Test 55 => ONIE Update - DHCP Inexact - TFTP Server IP - Name 2
Test 56 => ONIE Update - DHCP Inexact - TFTP Server IP - Name 3
Test 57 => ONIE Update - DHCP Inexact - TFTP Server IP - Name 4
Test 58 => ONIE Update - DHCP Inexact - TFTP Server IP - Name 5
Test 59 => ONIE Update - DHCP Inexact - DHCP Server IP - Name 1
Test 60 => ONIE Update - DHCP Inexact - DHCP Server IP - Name 2
Test 61 => ONIE Update - DHCP Inexact - DHCP Server IP - Name 3
Test 62 => ONIE Update - DHCP Inexact - DHCP Server IP - Name 4
Test 63 => ONIE Update - DHCP Inexact - DHCP Server IP - Name 5
Test 64 => ONIE Update - IPv6 Neighbor - Name 1
Test 65 => ONIE Update - IPv6 Neighbor - Name 2
Test 66 => ONIE Update - IPv6 Neighbor - Name 3
Test 67 => ONIE Update - IPv6 Neighbor - Name 4
Test 68 => ONIE Update - IPv6 Neighbor - Name 5
Test 69 => ONIE Update - TFTP Waterfall - Name 1
Test 70 => ONIE Update - TFTP Waterfall - Name 2
Test 71 => ONIE Update - TFTP Waterfall - Name 3
Test 72 => ONIE Update - TFTP Waterfall - Name 4
Test 73 => ONIE Update - TFTP Waterfall - Name 5
Test 74 => Uninstall from UBoot
Test 75 => Uninstall from ONIE
Test 76 => Uninstall from NOS
Test 77 => Rescue from UBoot
Test 78 => Rescue from ONIE
Test 79 => Rescue from NOS
```

The required arguments to run a specific test again a DUT are:
* ```-c``` default is to use [config/onie-tests.json](docs/onie-tests.json), [docs/test-config.md](docs/test-config.md)
* ```-i``` DUT IP Address in CIDR format
* ```-m``` DUT MAC Address
* ```-I``` Interface the DUT will be communicating on
* ```-t``` test case

For brevity, the ```-d``` option can be used instead of ```-i,```,```-I```, ```-m``` and other options (More on options down below). An example DUT config file can be found in [config/dut-example.json](config/dut-example.json), [docs/dut-config.md](docs/dut-config.md).

**NOTE**: all CLI options take precedence over the DUT config file parameters.

Lastly, depending on which test case you are executing, OCE may need additional information in the form of options.  The exact list of options can be found by performing ```./test-onie.py -h```.  The options can be specified in the DUT config file or on the command line.

An example for command-line options:
```
-o onie_installer my_onie_installer.bin tftp_binary /home/carlos/bin/my_tftp
```

When you are done, you can exit the virtualenv by
```
(.venv) # deactivate
#
```

### eyes.py

```eyes.py``` allows for a DUT's output to be captured/logged using a serial 
connection, SSH, or Telnet along with providing a REST interface to perform
various actions like executing commands on a DUT via the hands module.

It takes the following arguments:
* Interface to bind against
* DUT config (same DUT configuration file test-onie.py uses)

Prior to running ```eyes.py```, please ensure that the python virtual
environment is activated.

```
usage: eyes.py [-h] [-d CONFIG] [-I INTERFACE] [-p PORT] [-v] [-O DIR]

OCE-EYES

optional arguments:
  -h, --help            show this help message and exit
  -d CONFIG, --dut-config CONFIG
                        DUT configuration file
  -I INTERFACE, --interface INTERFACE
                        Interface to bind against
  -p PORT, --port PORT  port to use
  -v, --verbose         increase the verbosity level
  -O DIR, --output-dir DIR
                        output director (default: output)
```

The following options are added to the dut-config:
* ```eyes_interface``` - the interface ```eyes.py``` will bind its REST port.  This can be the actual name of the interface (e.g. ```eth0```) or ```all``` to bind to all interfaces.
* ```eyes_port``` - the port the REST interface will bind to.
* ```eyes_dut_console_speed``` - when using the serial console connector, the baud speed to use (e.g. 115200).
* ```eyes_dut_password``` - the password to use when connecting to the DUT. Can be blank if no password is needed but option must be present.
* ```eyes_dut_port`` - the port to use when connecting to the DUT over ssh or telnet. Can be blank if the default service port is acceptable (22 and 23 respectively).
* ```eyes_dut_user``` - the user to use when connecting to the DUT over ssh or telnet. Can be blank if no user is needed but option must be present.
* ```eyes_dut_url``` - the URL to use when connecting to the DUT. The following forms are allowed:
   * ```console://PORT``` - ```console:///dev/ttyUSB0```
   * ```ssh://HOST``` - ```ssh://192.168.1.1```
   * ```telnet://HOST``` - ```telnet://192.168.1.1```

## Testing a NOS

To test a given NOS would typically end up having the user take a NOS and
use ONIE's image discovery to ensure it "installs" and runs properly.
However, this is woefully insufficient.

A NOS *should* obey the ONIE contract which includes:
* No modification to ONIE (files, partition layout, etc...)
* The ability for a user to uninstall a NOS and install another NOS
* The ability for a user to update ONIE after a NOS is installed
* The ability for a user to enter ONIE's rescue mode after a NOS is installed

### test-nos.sh

```test-nos.sh``` allows a user to determine if key files have been modified
to ONIE, along with partition layouts, and file system attributes.

It takes the following mandatory argument (COMMAND: ```init``` or ```check```)
along with some optional parameters.

Before we get started, ```test-nos.sh``` requires the following:
* ONIE release 2015.05
* mtree(1)

Starting with ONIE release 2015.05, uclibc is being built with the FTS subsystem
which allows for traversing file hierarchies efficiently. This is a requirement
for mtree(1) to work.  Also with this release, mtree is an optional utility
that can be enabled in ONIE during build time by including ```MTREE_ENABLE=yes```.

If mtree(1) is not present on a 2015.05 or later release, you can compile it.

```
# ./build-onie.py -b kvm_x86_64 -m 'MTREE_ENABLE=yes' -t demo
```

The above example compiles the KVM x86_64 ONIE VM with mtree(1) as part of the
image using the ```all``` and ```demo``` make targets.  If you are just wanting
the mtree(1) binary, look at build/kvm_x86_64/sysroot/usr/bin/mtree.

Now that you have the mtree(1) binary (and possibly in ONIE itself), we can
start using ```test-nos.sh```.

```
ONIE:~ # ./test-nos.sh -h
usage: test-nos.sh [-c COMMAND] [OPTIONS]
Test to see if ONIE has been altered by a NOS function (install, uninstall).
The default COMMAND is to perform 'check'.

COMMAND LINE OPTIONS

        -c
                Perform the following command.  Available commands are:

                check  -- Perform Check (default)
                init   -- Perform Initialization

        -d
                Use the following directory as the location to store the
                mtree index files. (default: /mnt/onie-boot/onie/config/etc/mtree)

        -h
                Help.  Print this message.

        -m
                Use the following mtree binary.
                (default: /usr/bin/mtree)

        -q
                Quiet.  No printing, except for errors.

        -v
                Be verbose.  Print what is happening.
ONIE:~ #
```

The first time we use ```test-nos.sh```, we must generate the mtree(1) index
files.  This is done by:

```
# ./test-nos.sh -c init
```

Once we have the index files, we can perform a NOS operation (install or uninstall)
and run ```test-nos.sh``` again to see if any files were modified.

```
# ./test-nos.sh -c check
```
or

```
# ./test-nos.sh
```

### Platform differences for NOS validation

On x86_64 platforms, onie is mounted read-write under ```/mnt/onie-boot```.
On other platforms, this mount doesn't exist.  By default, ```test-nos.sh```
creates the directory ```/mnt/onie-boot/onie/config/etc/mtree``` to store
the index files.  These files are only preserved on x86_64 which means they
can survive a boot/reboot of the device.  In order to make copying of these
index files easier on other platforms, you can use the ```-d DIR``` option
for ```test-nos.sh``` to use another directory.  This directory can then be
copied over to a file server for safe keeping and re-copied for verification.

On x86_64 platforms, the mass storage device is either gpt or msdos formatted
and as such we are able to check partition tables and file system attributes
to ensure compliance with NOS and Diag images.  On other platforms, this is not
possible as all NOR storage is defined in the DTS files and seen in ```/dev```
as ```mtd-*``` files.

Here's an example:

```
ONIE:/dev # ls -l mtd-*
lrwxrwxrwx    1 root     0                9 Apr  4 03:33 mtd-NOR -> /dev/mtd0
lrwxrwxrwx    1 root     0                9 Apr  4 03:33 mtd-board_eeprom -> /dev/mtd1
lrwxrwxrwx    1 root     0                9 Apr  4 03:33 mtd-onie -> /dev/mtd3
lrwxrwxrwx    1 root     0                9 Apr  4 03:33 mtd-open -> /dev/mtd2
lrwxrwxrwx    1 root     0                9 Apr  4 03:33 mtd-open2 -> /dev/mtd6
lrwxrwxrwx    1 root     0                9 Apr  4 03:33 mtd-uboot -> /dev/mtd5
lrwxrwxrwx    1 root     0                9 Apr  4 03:33 mtd-uboot-env -> /dev/mtd4
ONIE:/dev #
```

We can determine the block partition sizes.  We can also determine if a NOS and/or
DIAG image has been installed by using ```onie-env-get```.
