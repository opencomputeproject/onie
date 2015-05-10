#ONL Routing Tutorial
-------------------------------------------------

The goal of the tutorial is to ping between virtual hosts connected via
virtual routers.

These instructions walk you through setting up a virtual environment to
run nested virtual ONL KVM instances and Quagga on a virtual network and 
configure BGP/OSPF etc. routes, peering, and other fun things.


#Host Requirements
-------------------------------------------------

This tutorial assumes that you can create a virtual machine from the
'onl-routing-tutorial.iso'.  The tutorial ISO is a self-contained live CD 
of Open Network Linux (based on Debian Wheezy).  From the ISO, you will 
have to create a virtual machine with the following requirements

Requirements:
- Single CPU is ok, but multiple is recommended.
- 4GB of RAM
- ~300 MB of free diskspace

# Tutorial Overview
-------------------------------------------------

The goal of the tutorial is to ping between virtual hosts connected via
virtual routers.  With ONL, this would be much more interesting with 
physical hosts and physical routers (e.g., using `orc`), but virtually is
easier to setup for self-guided tutorial.  In principle, many of these same
steps will work with a physical setup.

1. Download the pre-built ISO 'onl-routing-tutorial.iso' and create a VM
2. Run the kvm-router-demo.sh script to spawn the virtual topology
3. Configure quagga on the corresponding routers so that they peer
4. Verify that the virtual hosts can ping each other through the routers


# Download Tutorial Image And Create VM
-------------------------------------------------

Download the image from:
    

# Start Up Virtual Hosts and Routers
-------------------------------------------------

    ./kvm-router-demo.sh -setup         # launch everything
    tmux a 
    
If you take a look at the kvm-router-demo.sh script, it does lots
of things:

* Creates .img files for each KVM router
* Creates lots of Linux containers for virtual hosts and routers
* Creates Linux bridges to act as virtual links between hosts and routers
* Assigns IP addresses to the virtual hosts
* Spawns a KVM instance with the console connected to `tmux` for each router

The script also supports the '-teardown' option to undo everything is setup (though
exiting the docker shell is probably cleaner) and '-show' to show the status
of various tutorial elements.


# Configuring the Routers and Hosts Networks

Now we configure our network to look like the reference topology:

![Tutorial Topology](https://github.com/opennetworklinux/ONL/tools/docker.tutorial/topology.png "Tutorial Topology")


From tmux, hit ctl+b and then '1' to go to the first router, login as root
(password 'onl'), and then cut and paste these commands:

    hostname router1
    exec bash
    ifconfig eth1 10.99.1.3 netmask 255.255.255.0
    ifconfig eth2 10.99.3.2 netmask 255.255.255.0
    echo 1 > /proc/sys/net/ipv4/ip_forward

And then confirm that R1 can reach H1 with:
    
    ping 10.99.1.2

Now use ctl+b and then '2' to switch to route2 and execute the equivalent commands:

    hostname router2
    exec bash
    ifconfig eth1 10.99.2.3 netmask 255.255.255.0
    ifconfig eth2 10.99.3.3 netmask 255.255.255.0
    echo 1 > /proc/sys/net/ipv4/ip_forward

And then confirm that R2 can reach H2 and R1 with:
    
    ping 10.99.2.2       # can we reach H2?
    ping 10.99.3.2       # can we reach R1?

Note that at this point, because there is no dynamic routing in place, H1 cannot ping H2:







#NOTES ON TUTORIAL DEVELOPMENT
-----------------------------------

* Tried to use docker instead of an ISO image
    ** The nested KVMs would hang when I pinged from one to the other - no idea why
    ** `screen` could never work - would just hang
    ** Existing ONL build infrastructure was easy to adapt to my needs (thanks Jeff!)
