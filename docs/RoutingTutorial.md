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
    cp /usr/share/doc/quagga/examples/zebra.conf.sample /etc/quagga/zebra.conf
    cp /usr/share/doc/quagga/examples/bgpd.conf.sample /etc/quagga/bgpd.conf
    sed -i.bak -e 's/hostname Router/hostname router1/' /etc/quagga/zebra.conf
    sed -i.bak -e 's/zebra=no/zebra=yes/' -e 's/bgpd=no/bgpd=yes/' /etc/quagga/daemons
    sed -i.bak -e 's/-A 127.0.0.1//' /etc/quagga/debian.conf
    adduser --system quagga --group && addgroup quaggavty
    chgrp quagga /var/run/quagga/ &&  chmod 775 /var/run/quagga/
    /etc/init.d/quagga start

And then confirm that R1 can reach H1 with:
    
    ping 10.99.1.2

Now use ctl+b and then '2' to switch to router2 and execute the equivalent commands:

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
    
    ping 10.99.2.2       # can we reach H2?
    ping 10.99.3.2       # can we reach R1?

Note that at this point, because there is no dynamic routing in place, H1 cannot ping H2:
    
    Jump to the H1 window with ctr-b and then '3'
    ping 10.99.2.2          # this will fail with network unreachable

    Jump to the H2 window with ctr-b and then '4'
    ping 10.99.1.2          # this will fail with network unreachable




# Add Neighbor and Redistribute Routes with iBGP
--------------------------------------------

Quagga has a standard, IOS-like looking shell called `vtysh`.

Run `vtysh` and issue some of your favorite CLI commands:
    vtysh               
        show running-config
        show bgp neighbot
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
'Established' connection.  Note that 'Active' or 'Idle' indiciate a
problem with the setup.

Now run `show ip route` to confirm we have learned the routes on both sides.

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
advanced steps you can take.

1. Spin up a third router 'r3' and play with that:
  1. Create two more bridges: br-r1-r3 and br-r2-r3
  2. Spin up another KVM instance with three interfaces (cut and paste from script)
  3. Use the unused eth0 interfaces from 'r1' and 'r2' to add the the new bridges
2. Withdrawl the iBGP routes and repeat with:
  1. OSPF
  2. ISIS
3. Change the AS number of one of 'r1' or 'r2' to something new for an eBGP peering
4. Repeat this tutorial with IPv6 addressing and routing

#NOTES ON TUTORIAL DEVELOPMENT
-----------------------------------

* Tried to use docker instead of an ISO image
    ** The nested KVMs would hang when I pinged from one to the other - no idea why
    ** `screen` could never work - would just hang
    ** Existing ONL build infrastructure was easy to adapt to my needs (thanks Jeff!)
