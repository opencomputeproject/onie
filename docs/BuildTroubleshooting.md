Summary
=============

Building images for embedded devices can be sometimes tricky.  It may involve
cross-compiling, kernel and package management, chroot(), and other system
devices that individually are not that complicated but come together to be a lot
of sharp edges.  Part of the value of ONL is the scripts that automate these steps
for you.  That said, with any automation, someone eventually needs to understand
what the steps are to fix it when things break.  This document tries to address
some of the most common sources of build problems.


chws and isolate
=============

The `mkws`, `chws`, and `isolate` commands all come together to build a dedicated
and isolated workspace to build the various switch images.


This 'isolate' environment actually does a number
of things including:
* creating a chroot() environment
* creating a Linux Network Namespace
        (http://blog.scottlowe.org/2013/09/04/introducing-linux-network-namespaces/)
and execs a shell inside that name space.  

With a workspace, you can have multiple builds running in parallel and
any ports that get bound actually get bound inside the name space so
that they do not conflict.

When properly setup, _inside_ the name space you should see:

        robs@ubuntu:~/work.onl/ONL$ cd ..
        robs@ubuntu:~/work.onl$ mkws -a amd65 ws.amd64
        # lots of output
        robs@ubuntu:~/work.onl$ cd ws.amd64
        robs@ubuntu:~/work.onl/ws.amd64$ chws
        (iso1:ws.amd64)robs@ubuntu:~/work.onl/ws.amd64$ ifconfig
        iso1      Link encap:Ethernet  HWaddr 5a:d3:21:66:13:21  
                  inet addr:10.198.0.1  Bcast:0.0.0.0  Mask:255.255.255.254     <=== IP inside workspace
                  inet6 addr: fe80::58d3:21ff:fe66:1321/64 Scope:Link
                  UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
                  RX packets:29 errors:0 dropped:0 overruns:0 frame:0
                  TX packets:4 errors:0 dropped:0 overruns:0 carrier:0
                  collisions:0 txqueuelen:1000 
                  RX bytes:8101 (7.9 KiB)  TX bytes:328 (328.0 B)
        [snip]
        (iso1:ws.amd64)robs@ubuntu:~/work.onl/ws.amd64$ route
        Kernel IP routing table
        Destination     Gateway         Genmask         Flags Metric Ref    Use Iface
        default         10.198.0.0      0.0.0.0         UG    0      0        0 iso1 <=== route out to host machine
        10.198.0.0      *               255.255.255.254 U     0      0        0 iso1

So, it is almost like a virtual machine *inside* a virtual machine.
This VM has IP 10.192.0.1 and has a default route to 10.192.0.0 (yes,
10.192.0.0 is a valid address).  If you look outside the network
namespace (e.g., on another shell), you should see the iso0 device has
IP 10.192.0.0:

        robs@ubuntu:~/work.onl/ONL$ ifconfig
        [snip]
        iso0      Link encap:Ethernet  HWaddr 1a:12:86:31:29:9b  
                  inet addr:10.198.0.0  Bcast:0.0.0.0  Mask:255.255.255.254     <=== the "router" for the workspace
                  inet6 addr: fe80::1812:86ff:fe31:299b/64 Scope:Link
                  UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
                  RX packets:9 errors:0 dropped:0 overruns:0 frame:0
                  TX packets:39 errors:0 dropped:0 overruns:0 carrier:0
                  collisions:0 txqueuelen:1000 
                  RX bytes:635 (635.0 B)  TX bytes:9298 (9.2 KB)

So the first thing to check is to make sure that you can ping from inside
the workspace to the 10.198.0.0 address:

        (iso1:ws.amd64)robs@ubuntu:~/work.onl/ws.amd64$ ping 10.198.0.0
        PING 10.198.0.0 (10.198.0.0) 56(84) bytes of data.
        64 bytes from 10.198.0.0: icmp_req=1 ttl=64 time=0.182 ms
        64 bytes from 10.198.0.0: icmp_req=2 ttl=64 time=0.059 ms
        # works!

If this step fails, then perhaps you have some kind of IP management
daemon (e.g., NetworkManager) turned on.  Verify the iso0 IP address on
the outside of the workspace and if it does not have an IP assigned or
if it is different from 10.192.0.0, this is probably the problem.

The second thing to check is to see if you can ping from inside the
workspace to the outside world:

        (iso1:ws.amd64)robs@ubuntu:~/work.onl/ws.amd64$ ping 8.8.8.8
        PING 8.8.8.8 (8.8.8.8) 56(84) bytes of data.
        64 bytes from 8.8.8.8: icmp_req=1 ttl=127 time=55.3 ms
        64 bytes from 8.8.8.8: icmp_req=2 ttl=127 time=47.2 ms
        # works!

If this does not work, then your Linux machine/VM does not have IP
forwarding enabled -- check the top of the QUICKSTART.readme instructions for
how to enable IP forwarding.

The third thing to try is to make sure that DNS resolution is working
inside the workspace:

        (iso1:ws.amd64)robs@ubuntu:~/work.onl/ws.amd64$ ping google.com
        PING google.com (74.125.239.130) 56(84) bytes of data.
        64 bytes from nuq05s02-in-f2.1e100.net (74.125.239.130): icmp_req=1 ttl=127 time=28.9 ms
        64 bytes from nuq05s02-in-f2.1e100.net (74.125.239.130): icmp_req=2 ttl=127 time=33.8 ms
        # works!

If this does not work, then check the /etc/resolv.conf inside the
workspace and make sure you can ping that DNS server.  It should match
the DNS server from your host Linux machine.
