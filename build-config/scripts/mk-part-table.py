#!/usr/bin/python

from struct import pack
import sys

# Simple program to generate a MBR partition table containing a single
# bootable primary partition, of type EFI system partition (type =
# 0xEF)
#
# - argv[1] -- Filename of ISO image to modify
# - argv[2] -- The sector offset for the partition
# - argv[3] -- The partition length in sectors

iso = sys.argv[1]
start = int(sys.argv[2])
length = int(sys.argv[3])

# File system type for EFI System Partition
fs_type = 0xef

# Helper function to convert raw sectors offsets into CHS values.
#
# See MBR partition table entry format here:
# http://en.wikipedia.org/wiki/Master_boot_record#Partition_table_entries
def chs(sector_z):
    C = sector_z / (63 * 255)
    H = (sector_z % (63 * 255)) / 63
    # convert zero-based sector to CHS format
    S = (sector_z % 63) + 1
    # munge accord to partition table format
    S = (S & 0x3f) | (((C >> 8) & 0x3) << 6)
    C = (C & 0xFF)
    return (C, H, S)

# Compute starting and ending CHS addresses for the partition entry.
(s_C, s_H, s_S) = chs(start)

(e_C, e_H, e_S) = chs(start + length - 1)

# Write the 66 byte partition table to bytes 0x1BE through 0x1FF in
# sector 0 of the .ISO.
#
# See the partition table format here:
# http://en.wikipedia.org/wiki/Master_boot_record#Sector_layout
f = open(iso, 'r+')
f.seek(0x1BE)
f.write(pack("<8BLL48xH", 0x80, s_H, s_S, s_C,
             fs_type, e_H, e_S, e_C, start, length, 0xaa55))
f.close()
