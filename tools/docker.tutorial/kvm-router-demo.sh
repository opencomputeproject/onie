#!/bin/sh



############
#
#
#  H1 --> h1-e0 : h1-e1
#	|-br-h1-r1-| 
#		r1-e0 <-- R1 --> r1-e1 
#			|-br-r1-r2-| 
#		r2-e1 <-- R2 --> r2-e0 
#	|-br-r2-h2-| 
#  h2-e1 : h2-e0 <-- H2
#

BRCTL=brctl
IP=ip
KVM=kvm

SCREEN=tutorial
BRIDGES="br-h1-r1 br-r1-r2 br-r2-h2"
INTERFACES="h1-eth1 h2-eth1 $BRIDGES"
NAMESPACES="h1 h2"
PREFIX="10.99"
SWI=onl-i386-kvm.swi
SRC_KVM_IMG=onl-i386.img
#KVM_OPTS="-m 1024 -cdrom loader-i386.iso -boot d -nographic -hda onl-i386.img"
KVM_OPTS="-m 1024 -cdrom loader-i386.iso -boot d -nographic -chardev pty,id=pty0 "

do_setup() {

   # shipping the .swi is much smaller than shipping the .img!
   if [ ! -f $SRC_KVM_IMG ] ; then
           echo Making $SRC_KVM_IMG from $SWI
           mkdosfs -F 32 -C $SRC_KVM_IMG 1000000
           mcopy -i $SRC_KVM_IMG $SWI ::onl-i386.swi
           echo "SWI=flash:onl-i386.swi" > boot-config
           echo "NETDEV=ma1" >> boot-config
           #echo "NETAUTO=dhcp" >> boot-config
           mcopy -i $SRC_KVM_IMG boot-config ::boot-config
           rm boot-config
   fi

   if [ ! -f onl-r1.img ] ; then
        cp $SRC_KVM_IMG onl-r1.img
   fi

   if [ ! -f onl-r12img ] ; then
        cp $SRC_KVM_IMG onl-r2.img
   fi

    # Create KVM device 
    if [ ! -e /dev/kvm ]; then
        set +e
        mknod /dev/kvm c 10 $(grep '\<kvm\>' /proc/misc | cut -f 1 -d' ')   
        set -e
    fi

   for bridge in $BRIDGES; do 
      echo Adding bridge $bridge
      $BRCTL addbr $bridge || die "$BRCTL addbr $bridge Failed"
   done

   $IP link set br-h1-r1 address 00:11:11:aa:aa:aa
   $IP link set br-r1-r2 address 00:11:11:bb:bb:bb
   $IP link set br-r2-h2 address 00:11:11:cc:cc:cc

   echo Adding Namespaces
   for ns in $NAMESPACES ; do 
       echo Creating namespace $ns
       $IP netns add $ns
   done
	
   echo Adding h1 interfaces
   $IP link add dev h1-eth0 type veth peer name h1-eth1
   $BRCTL addif br-h1-r1 h1-eth1 || die "$BRCTL addif br-h1-r1 h1-eth1"
   $IP link set dev h1-eth0 up netns h1
   $IP netns exec h1 $IP addr change ${PREFIX}.1.2 broadcast ${PREFIX}.1.255 dev h1-eth0
   $IP netns exec h1 $IP link set dev lo up
   $IP netns exec h1 $IP route add ${PREFIX}.1.0/24 dev h1-eth0
   $IP netns exec h1 $IP route add default via ${PREFIX}.1.3

    
   echo Adding h2 interfaces
   $IP link add dev h2-eth0 type veth peer name h2-eth1
   $BRCTL addif br-r2-h2 h2-eth1 || die "$BRCTL addif br-h2-r2 h2-eth1"
   $IP link set dev h2-eth0 up netns h2
   $IP netns exec h2 $IP addr change ${PREFIX}.2.2 broadcast ${PREFIX}.2.255 dev h2-eth0
   $IP netns exec h2 $IP link set dev lo up
   $IP netns exec h2 $IP route add ${PREFIX}.2.0/24 dev h2-eth0
   $IP netns exec h2 $IP route add default via ${PREFIX}.2.3

   echo Bringing up all interfaces
   for intf in $INTERFACES ; do 
      $IP link set dev $intf up || die "$IP link set dev $intf up"
   done

   echo Adding bridge interfaces
   $IP addr change ${PREFIX}.1.1 broadcast ${PREFIX}.1.255 dev br-h1-r1 
   $IP route add ${PREFIX}.1.0/24 dev br-h1-r1
   $IP addr change ${PREFIX}.2.1 broadcast ${PREFIX}.2.255 dev br-r2-h2
   $IP route add ${PREFIX}.2.0/24 dev br-r2-h2
    # don't add an IP for the inter-router interface ; causes a loop(?)
   #$IP addr change ${PREFIX}.3.1 broadcast ${PREFIX}.3.255 dev br-r1-r2
   #$IP route add ${PREFIX}.3.0/24 dev br-r1-r2

    tmux new -s $SCREEN \; detach
    echo Starting ONL image Router1
    tmux new-window -n router1 "$KVM $KVM_OPTS \
            -name router1 \
            -vnc :0 \
            -net nic,macaddr=52:54:00:00:01:00 -net tap,ifname=r1-eth0,script=no,downscript=no \
            -net nic,macaddr=52:54:00:00:01:01 -net tap,ifname=r1-eth1,script=no,downscript=no \
            -net nic,macaddr=52:54:00:00:01:02 -net tap,ifname=r1-eth2,script=no,downscript=no \
            -hda onl-r1.img"
            #-net nic -net user,net=${PREFIX}.14.0/24,hostname=router1 \

   echo Starting ONL image Router2
   tmux new-window -n router2 "$KVM $KVM_OPTS \
            -name router2 \
            -vnc :1 \
            -net nic,macaddr=52:54:00:00:02:00 -net tap,ifname=r2-eth0,script=no,downscript=no \
            -net nic,macaddr=52:54:00:00:02:01 -net tap,ifname=r2-eth1,script=no,downscript=no \
            -net nic,macaddr=52:54:00:00:02:02 -net tap,ifname=r2-eth2,script=no,downscript=no \
            -hda onl-r2.img"
            #-net nic -net user,net=${PREFIX}.24.0/24,hostname=router2 \

   echo Starting Shell for H1
   tmux new-window -n H1 -t $SCREEN "ip netns exec h1 bash"

   echo Starting Shell for H2
   tmux new-window -n H2 -t $SCREEN "ip netns exec h2 bash"

   echo Waiting a bit for KVM to start
   sleep 2

   for intf in r1-eth1 r1-eth2 r2-eth1 r2-eth2 ; do 
	$IP link set dev $intf up
   done

    # attach R1:e1 to H1
    $BRCTL addif br-h1-r1 r1-eth1 || die "$BRCTL addif br-h1-r1 r1-eth1"
    # attach R2:e1 to H2
    $BRCTL addif br-r2-h2 r2-eth1 || die "$BRCTL addif br-r2-h2 r2-eth1"
    # attach R1:e2 to R2:e2
    $BRCTL addif br-r1-r2 r1-eth2 || die "$BRCTL addif br-r1-r2 r1-eth2"
    $BRCTL addif br-r1-r2 r2-eth2 || die "$BRCTL addif br-r1-r2 r2-eth2"
}

do_teardown() {

    echo '*** ' Killing all KVM instances
    killall qemu-system-x86_64

    echo '*** ' Bringing down all interfaces
    for intf in $INTERFACES ; do 
       $IP link set dev $intf down
    done
    for bridge in $BRIDGES; do 
       echo '*** ' Removing bridge $bridge
       $BRCTL delbr $bridge 
    done

    echo '*** ' Removing screen \'$SCREEN\'
    tmux kill-session -t $SCREEN
	
    echo '*** ' Removing Namespaces
    for ns in $NAMESPACES ; do 
        echo '*** ' Removing namespace $ns
        $IP netns delete $ns
    done

    echo '*** ' Removing Router KVM images
    rm onl-r1.img onl-r2.img

   # Not needed anymore
   #echo Removing h1 interfaces
   #$IP link del dev h1-eth0 type veth peer name h1-eth1
   #echo Removing h2 interfaces
   #$IP link del dev h2-eth0 type veth peer name h2-eth1

}

do_show () {
    echo '*** ' Bridges:
    $BRCTL show
    echo '*** ' Namespaces:
    $IP netns 
    echo '*** ' Interfaces:
    for intf in $INTERFACES ; do
       $IP addr show $intf
    done
    echo '*** ' KVM instances:
    pgrep qemu-system-x86_6
    echo '*** ' Screen instances
    tmux  ls

}

die () {
   echo '******' FAILED COMMMAND $1 >&2
   echo Dying.... >&2
   exit 1
}

do_usage() {
   echo "Usage: $0 <-setup|-teardown|-show>" >&2
   exit 1
}


if [ "X$1" = "X" ] ; then
   do_usage
fi

if [ `id -u` != 0 ] ; then
   die "You need to run this as root"
fi

case $1 in 
   -setup)
	do_setup ;;
   -teardown)
	do_teardown ;;
   -show)
	do_show ;;
   *)
	do_usage ;;
esac
