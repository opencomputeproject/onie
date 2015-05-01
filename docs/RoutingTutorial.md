#ONL Routing Tutorial
-------------------------------------------------

The goal of the tutorial is to ping between virtual hosts connected via
virtual routers.

These instructions walk you through setting up a docker environment to
run virtual ONL KVM instances and Quagga in a virtual network and 
configure BGP/OSPF etc. routes, peering, and other fun things.


#Host Requirements
-------------------------------------------------

This tutorial assumes that you have access to a Linux host (physical
server or VM) that is modern enough to run docker.  This typically means
a kernel newer than 3.10.x.

Requirements:
- docker v1.0 or above 
- About 3GB of free disk space
- About 4GB of RAM


# Tutorial Overview
-------------------------------------------------

The goal of the tutorial is to ping between virtual hosts connected via
virtual routers.  With ONL, this would be much more interesting with 
physical hosts and physical routers (e.g., using `orc`), but virtually is
easier to setup for self-guided tutorial.  In principle, many of these same
steps will work with a physical setup.

1. Download and install pre-built docker image 'opennetworklinux/routing-tutorial'
2. Run the kvm-router-demo.sh script to spawn the virtual topology
3. Configure quagga on the corresponding routers so that they peer
4. Verify that the virtual hosts can ping each other through the routers


# Download Tutorial Image
-------------------------------------------------

If your docker installation is working, this should be easy:

    docker.io pull onl/routing-tutorial
    docker.io run -i -t --privileged  \
        -h "tutorial" \
        opennetworklinux/routing-tutorial 

If you do not have docker installed on your system, consider
    sudo apt-get install docker.io

or
    wget -qO- https://get.docker.com/ | sh

Also, your docker binary might be called 'docker' not 'docker.io'
depending on your system. 



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

    dhclient ma1
    hostname router1
    exec bash
    ifconfig eth1 10.99.1.3 netmask 255.255.255.0
    ifconfig eth2 10.99.3.2 netmask 255.255.255.0

And then confirm that R1 can reach H1 with:
    
    ping 10.99.1.2

Now use ctl+b and then '2' to switch to route2 and execute the equivalent commands:

    dhclient ma1
    hostname router2
    exec bash
    ifconfig eth1 10.99.3.3 netmask 255.255.255.0
    ifconfig eth2 10.99.2.3 netmask 255.255.255.0

And then confirm that R2 can reach H2 and R1 with:
    
    ping 10.99.2.2       # can we reach H2?
    ping 10.99.3.2       # can we reach R1?

Note that at this point, because there is no dynamic routing in place, H1 cannot ping H2:




