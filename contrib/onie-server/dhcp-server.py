
#  Copyright (C) 2013 Daniel Walton <dwalton76@gmail.com>
#
#  SPDX-License-Identifier:     GPL-2.0

# This is a modified version of the following DHCP server
# https://github.com/psychomario/PyPXE

import socket
import binascii
import time
import sys
import subprocess

def dottedIPToDecimal(ip):
    octets = ip.split('.')
    decimal = 0
    for octet in octets:
          decimal = decimal * 256 + int(octet)
    return decimal

def decimalIPToDotted(ip):
    decimal = 256 * 256 * 256
    octets = []
    while (decimal > 0):
          octet,ip = divmod(ip,decimal)
          octets.append(str(octet))
          decimal = decimal/256
    return '.'.join(octets)

# Init global variables
if (len(sys.argv) <= 2):
    sys.stderr.write("You must specify the default gateway and subnet mask\n")
    exit()

port = 67
dnsserver = '8.8.8.8'
leasetime = 86400

# We'll use the IP of the laptop as the gw
gw = sys.argv[1]
server_host = gw
subnet_mask= sys.argv[2]

# Convert the gw address, mask, etc from X.X.X.X to a decimal number
gw_decimal = dottedIPToDecimal(gw)
subnet_mask_decimal = dottedIPToDecimal(subnet_mask)

# Calculate the subnet address and broadcast address based on the
# gw and mask
subnet_decimal = gw_decimal & subnet_mask_decimal

# Explanation here on why the "& 0xFFFFFFFF" is needed
# stackoverflow.com/questions/210629/python-unsigned-32-bit-bitwise-arithmetic
inverse_mask = ~subnet_mask_decimal & 0xFFFFFFFF
broadcast_decimal = subnet_decimal | inverse_mask
broadcast = decimalIPToDotted(broadcast_decimal)

# Create the (blank) leases table
leases=[]
for ip in range(subnet_decimal+2, broadcast_decimal):
    if ip == gw_decimal:
          continue

    ip_dotted= decimalIPToDotted(ip)
    leases.append([ip_dotted, False, '000000000000', 0])

rxs = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
rxs.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
rxs.setsockopt(socket.SOL_SOCKET, socket.SO_BROADCAST, 1)
# You have to bind to '' here, if you bind to the interface IP
# Linux and Mac boxes don't get the broadcast packets :(
rxs.bind(('', port))

txs = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
txs.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
txs.setsockopt(socket.SOL_SOCKET, socket.SO_BROADCAST, 1)
txs.bind((gw, port))

def release(): #release a lease after timelimit has expired
    for lease in leases:
        if not lease[1]:
           if time.time()+leasetime == leasetime:
               continue
           if lease[-1] > time.time()+leasetime:
              sys.stderr.write("Released %s\n" % (lease[0]))
              lease[1]=False
              lease[2]='000000000000'
              lease[3]=0

# Return the IP bound to a MAC address...if any
def get_lease(hwaddr):
    global leases
    for lease in leases:
        if hwaddr == lease[2]:
           return lease[0]

    for lease in leases:
        if (not lease[1]):
            return lease[0]

    return None

# Assign an IP to a MAC address
def assign_lease(hwaddr, requested_ip):
    global leases
    for lease in leases:
        if (lease[0] == requested_ip):
           lease[1]=True
           lease[2]=hwaddr
           lease[3]=time.time()
           return lease[0]

# generator for each of the dhcp fields
dhcpfields=[1, 1, 1, 1, 4, 2, 2, 4, 4, 4, 4, 6, 10, 192, 4, \
            "msg.rfind('\xff')", 1, None]
def slicendice(msg, slices=dhcpfields):
    for x in slices:

        #really dirty, deals with variable length options
        if (str(type(x)) == "<type 'str'>"):
            x = eval(x)

        yield msg[:x]
        msg = msg[x:]

def parseoptions(options_in_hex):
    options = {}

    while (options_in_hex):
        option = int(options_in_hex[0:2], 16)

        # END
        if (option == 255):
            # print "END OPTIONs"
            return options

        length = int(options_in_hex[2:4], 16)
        last_character = (length * 2) + 4
        value = options_in_hex[4:last_character]
        options_in_hex = options_in_hex[last_character:]
        # print "OPTION %s, LENGTH %s, VALUE %s" % (option, length, value)

        if (option == 53):
            options['type'] = int(value, 16)
            # print "TYPE: %s" % (options['type'])
        elif (option == 1):
            options['subnet_mask'] = int(value, 16)
            # print "MASK: %s" % (options['subnet_mask'])
        elif (option == 50):
            options['requested_ip'] = decimalIPToDotted(int(value, 16))
            # print "REQUEST_IP: %s" % (options['requested_ip'])
        elif (option == 61):
            id_type = value[:2]
            id_mac = value[2:]
            options['client_id_type'] = int(id_type, 16)
            options['client_id_mac'] = int(id_mac, 16)

        # Some option that we haven't implemented yet
        else:
            pass

    return options

def reqparse(s, message): #handles either DHCPDiscover or DHCPRequest
    # Packet format
    # http://en.wikipedia.org/wiki/Dynamic_Host_Configuration_Protocol

    # print "\nMSG:\n%s" % (binascii.hexlify(message))
    data = None
    client_mac = None
    hexmessage=binascii.hexlify(message)
    messagesplit=[binascii.hexlify(x) for x in slicendice(message)]

    # Some clients want the reply broadcast to them but most will set this
    # flag to 0x0000 which means they want you to unicast it to them.
    broadcast_reply = False
    flags = int(messagesplit[6], 16)
    if (flags == 32768):
        broadcast_reply = True

    # Supporting unicast replies on all the different platforms is a bit of
    # a pain because you have to use different "arp" syntax (windows, linux,
    # mac, etc are different) to add a static MAC entries.  We'll keep things
    # simple and always broadcast the reply
    broadcast_reply = True 

    # DHCP options are the 16th field in the packet
    options = parseoptions(messagesplit[15])
    client_mac = messagesplit[11]

    # DHCP Discover
    if (options['type'] == 1):
        # build DHCPOFFER
        lease = get_lease(client_mac)
        sys.stderr.write("RX Discover\n")
        sys.stderr.write("TX Offer %s\n" % (lease))
        data='\x02\x01\x06\x00'

	# XID
        data+=binascii.unhexlify(messagesplit[4])

	# SECS
        data+='\x00\x04'

        # FLAGS
        if (broadcast_reply):
            data+='\x80\x00'
        else:
            data+='\x00\x00'

        # Address for client
        data+='\x00'*4+socket.inet_aton(lease)

        # Server IP
        data+=socket.inet_aton(server_host)

        # Gateway IP?
        data+='\x00'*4

        # Client MAC Address
        data+=binascii.unhexlify(client_mac)

        # 10 octets of 0s
        data+='\x00'*10

        # 192 octets of 0s for BOOTP legacy
        data+='\x00'*192

        # Magic Cookie
        data+='\x63\x82\x53\x63'

        # DHCP Options...
        # 53 = DHCP Offer
        data+='\x35\x01\x02'

        # 54 = DHCP Server
        data+='\x36\x04'+socket.inet_aton(server_host)

        # 51 = Lease Time
        data+='\x33\x04'+binascii.unhexlify(hex(leasetime)[2:].rjust(8,'0'))

        #  1 = Subnet Mask
        data+='\x01\x04'+socket.inet_aton(subnet_mask)

        # 28 = Broadcast Address
        data+='\x1c\x04'+socket.inet_aton(broadcast)

        #  3 = Router
        data+='\x03\x04'+socket.inet_aton(gw)

        #  6 = DNS Server
        data+='\x06\x04'+socket.inet_aton(dnsserver)

        # End
        data+='\xff'

    # DHCP Request
    elif (options['type'] == 3 and 'requested_ip' in options):
        lease = assign_lease(client_mac, options['requested_ip'])

        # build DHCPACK
        sys.stderr.write("RX Request %s, lease %s\n" %
			 (options['requested_ip'], lease))
        sys.stderr.write("TX Ack\n\n")
        data='\x02\x01\x06\x00'
        data+=binascii.unhexlify(messagesplit[4]) # XID
        data+='\x00\x00'# SECS

        # FLAGS
        if (broadcast_reply):
            data+='\x80\x00'
        else:
            data+='\x00\x00'

        # Client IP
        data+='\x00'*4

	# Your (Client) IP
        data+=binascii.unhexlify(messagesplit[15][messagesplit[15].\
			         find('3204')+4:messagesplit[15].\
				 find('3204')+12])
        data+=socket.inet_aton(server_host)+'\x00'*4
        data+=binascii.unhexlify(client_mac)+'\x00'*202

        # Magic Cookie
        data+='\x63\x82\x53\x63'

        # DHCP Options...
        # 53 = DHCP Offer
        data+='\x35\x01\05'

        # 54 = DHCP Server
        data+='\x36\x04'+socket.inet_aton(server_host)

        #  1 = Subnet Mask
        data+='\x01\x04'+socket.inet_aton(subnet_mask)

	#  3 = Router
        data+='\x03\x04'+socket.inet_aton(server_host)

	# 51 = Lease Time
        data+='\x33\x04'+binascii.unhexlify(hex(leasetime)[2:].rjust(8,'0'))

        # End
        data+='\xff'

    if (data):
        if (broadcast_reply):
            time.sleep(2)
            txs.sendto(data, ('<broadcast>', 68)) #reply
        elif (lease):
            # For now this elif will never run because we set broadcast_reply
            # to True

            # We need to add a static arp entry for the lease IP address since
            # we are about to send a unicast packet destined for that IP.
            # Windows will ARP if we don't do this.

            # This is the syntax for windows.  You have to run the ONIE server
            # as Administrator for this to work.
            client_mac_pretty = "%s-%s-%s-%s-%s-%s" % \
                                (client_mac[0:2],
                                 client_mac[2:4],
                                 client_mac[4:6],
                                 client_mac[6:8],
                                 client_mac[8:10],
                                 client_mac[10:12])
            print "arp -s %s %s %s" % (lease, client_mac_pretty, gw)
            subprocess.Popen(["arp", "-s", lease, client_mac_pretty, gw],
                             stdout=subprocess.PIPE,
                             stderr=subprocess.PIPE,
                             shell=False)
            txs.sendto(data, (lease, 68)) #reply
        else:
            sys.stderr.write("ERROR: Could not get an IP for %s" % client_mac)

# main loop
while 1:
    try:
        (message, address) = rxs.recvfrom(8192)
        # only serve if a dhcp request
        if not message.startswith('\x01') and not address[0] == '0.0.0.0':
            continue
        reqparse(rxs, message)
        release()
    except KeyboardInterrupt:
        exit()
