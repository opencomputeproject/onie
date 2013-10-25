
# This program is a DHCP server, web server and HTTP proxy all rolled into one.
# The goal of this program is help boot the OS on a switch that uses ONIE to
# install its operating system.  Once the user has installed python on their
# laptop, desktop, etc they can run this program which launches the servers
# needed by ONIE to install an OS on a bare-metal switch.
#
# This program is designed to run on multiple platforms (linux, windows, etc)

import socket
import os.path
import re
import subprocess
import select
import sys
from threading import Thread
from Queue import Queue, Empty
from shutil import copyfile

# This queue is used for storing STDOUT and STDERR messages from the three
# servers that we will start
io_q = Queue()

def clearScreen():
    os.system('cls' if os.name=='nt' else 'clear')
    return

def pauseUntilEnter(msg):
    raw_input(msg)
    return

def streamWatcher(identifier, stream):
    for line in stream:
        io_q.put((identifier, line))

    if not stream.closed:
        stream.close()

def printer():
    while True:
        try:
            # Block for 1 second.
            item = io_q.get(True, 1)
        except Empty:
            # No output in either stream for a second. Are we done?
            if web_proc.poll() is not None:
                break
        else:
            identifier, line = item
            print identifier + ':', line.rstrip()

# Make sure there is an onie-installer image in the onie-server directory.
clearScreen()
onie = "onie-installer"
if (not os.path.exists(onie)):
    print "We do not have an onie-installer image. Please place an " \
          "onie-installer binary for the OS you wish to install, in the " \
          "same directory as this script.  You should name the image " \
          "'onie-installer'\n"
    exit()

# Figure out what interfaces we have and their IP addresses. If we have two
# interfaces (ideally we will) then ask which interface will be connected to
# the bare-metal switch and which will be used for Internet access
print "We need to determine which of the interfaces on your laptop " \
      "is connected to the Internet and which is connected to the switch " \
      "you want to boot."
inside_ip = False
outside_ip = False
for ip in socket.gethostbyname_ex(socket.gethostname())[2]:

    # Skip over any 127.X.X.X addresses or the default 169.254.X.X
    # address for windows
    if (ip.startswith("127.") or ip.startswith("169.254.")):
       next

    print "\nWhat type of interface is %s?" % ip
    print "1: This interface is connected to the Internet"
    print "2: This interface is connected to my bare-metal switch"
    print "3: Neither...ignore it"
    int_type = False

    while (not int_type):
        int_type = raw_input('')
        if (int_type):
            int_type = int(int_type)

        if (int_type == 1):
            outside_ip = True
        elif (int_type == 2):
            inside_ip = ip
            mask = raw_input('\nSubnet Mask [255.255.255.0]: ')
            if (not mask):
                mask = "255.255.255.0"
        elif (int_type == 3):
            pass
        else:
            print "ERROR: '%s' is not a valid option" % int_type
            int_type = False
clearScreen()

# On a linux system socket.gethostname() only returns the IP addresses that
# have an entry in /etc/hosts.  The user may not have a name assigned to the
# interface connecting to the switch so prompt them to let them enter it
# manually.
if (not inside_ip):
    print "Hmmm, we couldn't find the IP address of the interface that is " \
          "connected to your bare-metal switch.  Please enter it manually:\n"
    inside_ip = raw_input("IP Address: ")
    if (inside_ip):
        mask = raw_input('\nSubnet Mask [255.255.255.0]: ')
        clearScreen()
        if (not mask):
            mask = "255.255.255.0"

if (not inside_ip):
    sys.stderr.write("ERROR: You need an IP interface that is connected to " \
                     "your bare-metal switch.\n")
    exit()

if (not outside_ip):
    print "Hmmm, we couldn't find the IP address of the interface that is " \
          "connected to the Internet.  Please enter it manually or just " \
          "press ENTER if you don't have one.\n"
    outside_ip = raw_input("IP Address: ")
    clearScreen()

# See if we can ping to the outside world.  This isn't critical but if it fails
# then print a message explaining that apt commands will fail.
if (not outside_ip):
    print "You do not have an interface that is connected to the Internet. " \
          "This isn't a huge deal, just be aware that your switch will not " \
          "have Internet connectivity to do things such as 'apt-get'.\n"
    pauseUntilEnter("Press ENTER to continue\n")
    clearScreen()

# Start a DHCP server that listens on the INSIDE interface.
print "Starting the DHCP server, Web server and Proxy server...\n"
dhcp_proc = subprocess.Popen(["python", "dhcp-server.py", inside_ip, mask],
                             stdout=subprocess.PIPE,
                             stderr=subprocess.PIPE,
                             shell=False)

# Start a web server that listens on the INSIDE interface.
web_proc = subprocess.Popen(["python", "web-server.py", inside_ip],
                            stdout=subprocess.PIPE,
                            stderr=subprocess.PIPE,
                            shell=False)

# If we have an OUTSIDE interface then start a proxy server that listens on the
# INSIDE interface.
if (outside_ip):
    proxy_proc = subprocess.Popen(["python", "proxy-server.py", inside_ip],
                                  stdout=subprocess.PIPE,
                                  stderr=subprocess.PIPE,
                                  shell=False)
else:
    proxy_proc = False

print "The DHCP, Web, and Proxy servers are all running.\nWhen you have " \
      "finished installing the OS on your switch press ENTER to shut down " \
      "the DHCP, Web, and Proxy servers.\n"

# Now print the STDOUT and STDERR from all three servers
if (dhcp_proc):
    Thread(target=streamWatcher, name='dhcp-stderr-watcher',
           args=('DHCP', dhcp_proc.stderr)).start()

if (web_proc):
    Thread(target=streamWatcher, name='web-stderr-watcher',
           args=('HTTP', web_proc.stderr)).start()

if (proxy_proc):
    Thread(target=streamWatcher, name='proxy-stderr-watcher',
           args=('PROXY', proxy_proc.stderr)).start()

Thread(target=printer, name='printer').start()

# Wait for the user to press ENTER to shutdown everything
pauseUntilEnter('')

if (dhcp_proc):
    dhcp_proc.terminate()

if (web_proc):
    web_proc.terminate()

if (proxy_proc):
    proxy_proc.terminate()

