# DUT (Device Under Test) Config File for OCE (ONIE Compliance Environment)

This file will go over the basic definition and various sections of the DUT config
file that can be used by OCE.

## Structure

The config file is a JSON object with the following attributes:
* ```name```
* ```mac_address```
* ```ip_cidr```
* ```options```

## name
This is the name of this particular DUT config file.  This is intended to be used
by the user for easy identification.

## mac_address
This is the MAC address of the DUT.  The format of the MAC can be either ```:```
separated or without them.

## ip_cidr
This the IP address of the DUT in CIDR format.  CIDR information is used to build
out the appropriate subnet ranges for DHCP and also for validation checks by OCE
prior to execution, if selected by the user.

## options
This is a dictionary of key, value pairs that can be provided to OCE.  To obtain
the list of all supported options, execute the following ```testing-onie.py -h```.
