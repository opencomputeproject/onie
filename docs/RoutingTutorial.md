#ONL Routing Tutorial
-------------------------------------------------

The goal of the tutorial is to setup a virtual network of ONL KVM images
running as virtual routers, setup Quagga, and ping between virtual hosts
connected via virtual routers.

These instructions walk you through setting up a virtual environment to
run nested virtual ONL KVM instances and Quagga on a virtual network and 
configure BGP/OSPF etc. routes, peering, and other fun things.

The goal of the tutorial is to advertise routes using dynamic routing
protocols and ping between virtual hosts connected via virtual routers.
With ONL, this would be much more interesting with physical hosts and
physical routers (e.g., using `orc`), but virtually with software is
easier to setup for self-guided tutorial.  Many of these same steps will
translate with a physical setup.

## Tutorial Overview

1. Verify your host satisfies the tutorial requirements
2. Download the tutorial tarball and install in your environment
3. Run the kvm-router-demo.sh script to spawn the virtual topology
4. Configure quagga on the corresponding routers so that they peer
5. Verify that the virtual hosts can ping each other through the routers
6. Consider suggested advanced steps in the same virtual environment

#Host Requirements
-------------------------------------------------

This tutorial assumes that you have access to a modern Linux host
(physical or virtual) with a modest collection of standard utilities
including KVM and Linux bridge utilities.  While in theory this tutorial
could work in many places, it was developed and heavily tested in an
Ubuntu 14.04 server installation so that is recommended.

Host Requirements:

- Single CPU is OK, but multiple is recommended.
- 4+GB of RAM
- ~400 MB of free disk space
- Linux KVM
- Linux bridge utilities
- DOS FS tools and mtools package
- iproute2
- tmux

If you are on an Ubuntu-based system, you can cut and paste this line:

    sudo apt-get update && sudo apt-get install -y \
                bridge-utils \
                dosfstools \
                iproute \
                mtools \
                net-tools \
                qemu-kvm \
                sudo \
                tcpdump \
                tmux \
                traceroute


# Download Tutorial
-------------------------------------------------

Download the tutorial 99MB tarball from one of these methods:

1. ONL Website: http://opennetworklinux.org/binaries/routing-tutorial.tgz
2. Dropbox:     https://www.dropbox.com/sh/9n655wxkbnjw9zv/AADOqSdsSy1cw6-UkZ7YOAMFa?dl=0

Work is in progress to make a docker image and an ISO to ease installation.


The tarball contains three files:

* kvm-router-demo.sh     -- the script that creates the virtual network
* loader-i386.iso        -- the ONL KVM boot loader .iso
* onl-i386-kvm.swi       -- the ONL .SWI file with the router software


# Start Up Virtual Hosts and Routers
-------------------------------------------------

In theory, given a modern Linux system and the above dependencies, the
tutorial setup should be as simple as:

    ./kvm-router-demo.sh -setup         # launch everything
    tmux a                              # attach to the tutorial

If you take a look at the kvm-router-demo.sh script, it does lots
of things:

* Creates .img files for each KVM router
* Creates lots of Linux containers for virtual hosts and routers
* Creates Linux bridges to act as virtual links between hosts and routers
* Assigns IP addresses to the virtual hosts
* Spawns a KVM instance with the console connected to `tmux` for each router

The script also supports the '-teardown' option to undo all of the
virtual machines, links, bridges, etc. and '-show' to show the status
of various tutorial elements.

When working correctly, `kvm-router-demo.sh -setup` should output:

    Making onl-i386.img from onl-i386-kvm.swi
    mkfs.fat 3.0.26 (2014-03-07)
    Adding bridge br-h1-r1
    Adding bridge br-r1-r2
    Adding bridge br-r2-h2
    Adding Namespaces
    Creating namespace h1
    Creating namespace h2
    Adding h1 interfaces
    Adding h2 interfaces
    Bringing up all interfaces
    Adding bridge interfaces
    Starting ONL image Router1
    Starting ONL image Router2
    Starting Shell for H1
    Starting Shell for H2
    Waiting a bit for KVM to start

If this script does not work for you, please check your dependencies
per above.  If you continue to be stuck, please mail the mailing list
(http://opennetlinux.org/community) or if this is a live tutorial,
call for help at the appropriate time.

# Configuring the Routers and Hosts Networks
-----------------------------------------------------------

Once the virtual hosts and routers are running, we configure our network
to look like the reference topology:

![Tutorial Topology](https://raw.githubusercontent.com/opennetworklinux/ONL/master/tools/docker.tutorial/topology.png "Tutorial Topology")


From tmux, hit ctl+b and then '1' to go to the first router, login as root
(password 'onl'), and then cut and paste these commands:

    hostname router1
    exec bash
    ifconfig eth1 10.99.1.3 netmask 255.255.255.0
    ifconfig eth2 10.99.3.2 netmask 255.255.255.0
    echo 1 > /proc/sys/net/ipv4/ip_forward
    cp /usr/share/doc/quagga/examples/zebra.conf.sample /etc/quagga/zebra.conf
    cp /usr/share/doc/quagga/examples/bgpd.conf.sample /etc/quagga/bgpd.conf
    sed -i.bak -e 's/hostname Router/hostname router1/' /etc/quagga/zebra.conf
    sed -i.bak -e 's/zebra=no/zebra=yes/' -e 's/bgpd=no/bgpd=yes/' /etc/quagga/daemons
    sed -i.bak -e 's/-A 127.0.0.1//' /etc/quagga/debian.conf
    adduser --system quagga --group && addgroup quaggavty
    chgrp quagga /var/run/quagga/ &&  chmod 775 /var/run/quagga/
    /etc/init.d/quagga start

And then confirm that R1 can reach H1 with:
    
    ping 10.99.1.2      # can R1 reach H1?

Now use ctl+b and then '2' to switch to router2, login with root/onl,
and execute the matching commands:

    hostname router2
    exec bash
    ifconfig eth1 10.99.2.3 netmask 255.255.255.0
    ifconfig eth2 10.99.3.3 netmask 255.255.255.0
    echo 1 > /proc/sys/net/ipv4/ip_forward
    cp /usr/share/doc/quagga/examples/zebra.conf.sample /etc/quagga/zebra.conf
    cp /usr/share/doc/quagga/examples/bgpd.conf.sample /etc/quagga/bgpd.conf
    sed -i.bak -e 's/hostname Router/hostname router2/' /etc/quagga/zebra.conf
    sed -i.bak -e 's/zebra=no/zebra=yes/' -e 's/bgpd=no/bgpd=yes/' /etc/quagga/daemons
    sed -i.bak -e 's/-A 127.0.0.1//' /etc/quagga/debian.conf
    adduser --system quagga --group && addgroup quaggavty
    chgrp -R quagga /etc/quagga /var/run/quagga/ &&  chmod -R 775 /var/run/quagga/ /etc/quagga
    /etc/init.d/quagga start

And then confirm that R2 can reach H2 and R1 with:
    
    ping 10.99.2.2       # can R2 reach H2?
    ping 10.99.3.2       # can R2 reach R1?

Note that at this point, because there is no dynamic routing in place,
H1 cannot ping H2.  To verify, Jump to the H1 window with ctr-b and then '3' 

    ping 10.99.2.2          # this will fail with network unreachable

Jump to the H2 window with ctr-b and then '4'

    ping 10.99.1.2          # this will fail with network unreachable


# Add Neighbor and Redistribute Routes with iBGP
--------------------------------------------

Quagga has a standard, IOS-like looking shell called `vtysh`.

Run `vtysh` and issue some of your favorite CLI commands:
    vtysh               
        show running-config
        show bgp neighbor
        show interface

For the basic example, we are going to setup iBGP peering between
router1 and router2 so that H1 and H2 can reach each other.

On router1, in the vtysh prompt:

    conf t
       router bgp 7675
         neighbor 10.99.3.3 remote-as  7675
         network 10.99.1.0/24
         end

On router2, in the vtysh prompt:

    conf t
       router bgp 7675
         neighbor 10.99.3.2 remote-as  7675
         network 10.99.2.0/24
         end


Now run `show bgp neighbors` to confirm we are correctly peered with an
'Established' connection.  Note that 'Active' or 'Idle' indicate a
problem with the setup.

Now run `show ip route` to confirm we have learned the routes on both sides.  Your
output should look like this (as seen from R1):

    Codes: K - kernel route, C - connected, S - static, R - RIP,
    O - OSPF, I - IS-IS, B - BGP, A - Babel,
    > - selected route, * - FIB route

    C>* 10.99.1.0/24 is directly connected, eth1
    B>* 10.99.2.0/24 [200/0] via 10.99.3.3, eth2, 00:00:05
    C>* 10.99.3.0/24 is directly connected, eth2
    C>* 127.0.0.0/8 is directly connected, lo

Now jump to H1 (ctl-b + '3') and run a traceroute from 10.99.1.2 to 10.99.2.2,
and you should be able to see each hop like this:

        root@h1:~# traceroute -n 10.99.2.2
        traceroute to 10.99.2.2 (10.99.2.2), 30 hops max, 60 byte packets
        1  10.99.1.3  3.283 ms  1.257 ms  1.501 ms
        2  10.99.3.3  1563.713 ms  1565.277 ms  1565.396 ms
        3  10.99.2.2  1565.538 ms  1565.690 ms  1566.343 ms

Congrats on getting this far!  You have a working network!

#Advanced Steps
-------------------------------------------------

Once you are done with the basic tutorial, there are a number of more
advanced steps you can take.  There are not step by step instructions
(yet) for these, but from the existing examples it should be possible
to make some progress here.

1. Spin up a third router 'r3' and play with that:
  1. Create two more bridges: br-r1-r3 and br-r2-r3
  2. Spin up another KVM instance with three interfaces (cut and paste from script)
  3. Use the unused eth0 interfaces from 'r1' and 'r2' to add the the new bridges
  4. Once 'r3' is up, virtually bring down links with `ifconfig $bridge down` for each of the bridges
2. Withdrawal the iBGP routes and repeat with:
  1. OSPF
  2. ISIS
3. Change the AS number of one of 'r1' or 'r2' to something new for an eBGP peering
4. Repeat this tutorial with IPv6 addressing and routing


#Trouble Shooting
------------------------------------------------

* If you get into trouble, the router VM images are stateless; just issue the `reboot` command to start again
* If you find/cause a packet forwarding loop:
   * You can disable it by running ctr+b '0' to jump to the host and `ifconfig br-r1-r2 down` to down the link

#Tutorial Notes
------------------------------------------------

* The virtual environment is nice but has a number of short comings that are not indicative of ONLs hardware performance
   * There is a lot of jitter and latency in software forwarding
   * Running `reset` in the KVM console seems to hang (!?) the console

* There is unfinished progress towards wrapping this tutorial with Docker:
   * See https://github.com/opennetworklinux/ONL/tree/master/tools/docker.tutorial
   * Pre-built result is at `docker fetch opennetworklinux/routing-tutorial`  
   * Something (&^%$!@) causes packet duplication/looping which causes the VMs to slow to a crawl
   * Current belief of culprit is using bridge-utils inside docker with OVS
   * Definitely worth trying to port the kvm-router-demo.sh script to use OVS

* There is unfinished progress towards wrapping this tutorial with an ISO live cd:
   * Current work product is available at https://github.com/opennetworklinux/ONL/tree/master/builds/kvm/i386/tutorial
   * This should be easy to get working; just ran out of time
