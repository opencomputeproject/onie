Description
-----------
This program is a DHCP server, web server and HTTP proxy all rolled into one. The goal of this program is help install an OS on a bare-metal switch, using only a windows, linux or OSX laptop/PC.  


Instructions
------------
- Download the OS you would like to install and save it as onie-installer.   The onie-installer image must go in the same directory as the onie-server.py file.
- Start the ONIE server program via "python onie-server.py".   If you are on a Mac or Linux use sudo "sudo python onie-server.py"
- Answer a few questions to start the DHCP, HTTP and proxy servers
- ONIE should request a DHCP address and then begin downloading the onie-installer image via the web server


HTTP Proxy Server
-----------------
Some operating systems support downloading updates or new packages via HTTP.  onie-server.py launches a HTTP proxy server so point your switch towards that proxy in order to download updates or new packages to your switch. The proxy server listens on the IP address of your laptop (the interface connected to your bare-metal switch) on port 8080.

For example on debian based operating systems you can use "apt" to download updates and new packages via HTTP.  There are detailed instructions here on how to tell apt to use a http proxy:
https://help.ubuntu.com/community/AptGet/Howto#Setting_up_apt-get_to_use_a_http-proxy

In a nutshell you do:
export http_proxy=http://yourproxyaddress:proxyport

Example:
If 10.1.1.1 is the IP address on your laptop then on the switch do
export http_proxy=http://10.1.1.1:8080


Shutting Down The Servers
-------------------------
Once you have finished installing the operating system on your switch you can press ENTER in the window where you are running onie-server.py to shutdown the DHCP, web and HTTP proxy servers.
