# DHCPv6 RFC 5970 Network-Boot — Verification Guide

## What this patch does

Adds DHCPv6 installer discovery to ONIE. A switch can now obtain its
ONIE installer URL from a DHCPv6 server via **Boot File URL (option 59,
RFC 5970)** in addition to the existing DHCPv4 path.

**Components changed:**

- `patches/busybox/udhcp6-additional-options.patch` — extends `udhcpc6`
  to request and parse option 59 (Boot File URL), 60 (Boot File Param),
  61 (Client Arch Type), 62 (NII), plus 23/24/39. Exports the URL as
  the `bootfile` env var for `-s` handler scripts.
- `rootconf/default/bin/discover` — adds `sd_dhcp6()`, which calls
  `udhcpc6 -O 59` and feeds the result into the installer discovery loop.
- `rootconf/default/lib/onie/udhcp6_sd` — maps `$bootfile` →
  `onie_disco_bootfile` (the ONIE installer URL variable).
- `rootconf/default/lib/onie/udhcp6_net` — configures the management
  interface IPv6 address and DNS from the DHCPv6 reply.
- `rootconf/default/etc/init.d/networking.sh` — adds DHCPv6 management
  interface bring-up.

---

## Prerequisites

**Host packages:**
```
docker.io   qemu-system-x86_64   libvirt-daemon-system
virsh       dnsmasq               python3
```

**Notes:**
- Docker must be able to reach the internet (IPv6 or IPv4).
  On IPv6-only hosts, `build-onie-kvm.sh` uses `--network host`
  automatically.
- The `libvirt-qemu` user needs read access to files under your home
  directory (`chmod o+x $HOME` if needed).

---

## Topology

```
  ┌──────────── netns: onie-test ────────────┐
  │                                          │
  │  dnsmasq  ──── option 59 bootfile-url    │
  │  python3 http.server ──── installer      │
  │                     │                    │
  │               veth-ns (2001:db8::1/64)   │
  └──────────────────┬───────────────────────┘
                 veth-br
                     │
                 br-onie (bridge)
                     │
                 tap-onie
                     │
           ┌─────────┴──────────┐
           │   ONIE guest VM    │
           │  MAC 00:11:22:33:44:55  │
           └────────────────────┘
```

---

## Step 1 — Build the ONIE image

Run on a Linux host with Docker installed:

```sh
cd <onie-tree>
./contrib/dhcp6-emulation/build-onie-kvm.sh
```

Artifacts produced in `build/images/`:
```
kvm_x86_64-r0.vmlinuz
kvm_x86_64-r0.initrd
onie-updater-x86_64-kvm_x86_64-r0
onie-recovery-x86_64-kvm_x86_64-r0.iso
demo-installer-x86_64-kvm_x86_64-r0.bin
```

The script builds the `onie-build` container image from
`contrib/build-env/` on first run, applies build-config overrides
(Secure Boot off, `CONFIG_IPV6_AUTOCONF=y`), builds, then restores
the source tree to pristine.

---

## Step 2 — Quick script test (no VM required)

```sh
./contrib/dhcp6-emulation/test-udhcp6-sd.sh
```

Expected output:
```
ONIE_PARMS:onie_disco_bootfile@@http://[2001:db8::1]:8080/onie-installer##
PASS
```

This confirms `udhcp6_sd` correctly maps the `bootfile` env var to
`onie_disco_bootfile` without requiring a network or VM.

---

## Step 3 — End-to-end boot test

### 3a. Stage the HTTP payload

```sh
mkdir -p /tmp/onie-payload
cp build/images/demo-installer-x86_64-kvm_x86_64-r0.bin \
   /tmp/onie-payload/onie-installer
cp build/images/onie-updater-x86_64-kvm_x86_64-r0 \
   /tmp/onie-payload/
```

### 3b. Bring up the DHCPv6 test network

```sh
sudo INSTALLER_URL='http://[2001:db8::1]:8080/onie-installer' \
     PAYLOAD_DIR=/tmp/onie-payload \
     ./contrib/dhcp6-emulation/setup-dhcp6-test.sh up
```

### 3c. Create a fresh VM disk

```sh
qemu-img create -f qcow2 /tmp/onie-disk.qcow2 20G
chmod a+r /tmp/onie-disk.qcow2
```

### 3d. Embed ONIE (first time only)

Edit `onie-vm.xml.in` to set `@BOOT_DEV@` → `cdrom` and uncomment the
CDROM block. Render and define:

```sh
sed -e 's#@NAME@#onie-dhcp6#g' \
    -e 's#@QCOW2@#/tmp/onie-disk.qcow2#g' \
    -e 's#@TAP@#tap-onie#g' \
    -e 's#@MAC@#00:11:22:33:44:55#g' \
    -e 's#@RECOVERY_ISO@#'"$PWD"'/build/images/onie-recovery-x86_64-kvm_x86_64-r0.iso#g' \
    contrib/dhcp6-emulation/onie-vm.xml.in > /tmp/onie-vm.xml
virsh define /tmp/onie-vm.xml
virsh start onie-dhcp6 && virsh console onie-dhcp6
```

In the ONIE console, run:
```
onie-self-update -e http://[2001:db8::1]:8080/onie-updater-x86_64-kvm_x86_64-r0
```

After ONIE embeds and halts, switch `@BOOT_DEV@` → `hd`, remove the
CDROM block, re-render, and `virsh define` again.

### 3e. Boot and trigger DHCPv6 discovery

```sh
virsh start onie-dhcp6
virsh console onie-dhcp6 | tee /tmp/onie-console.log
```

### 3f. Verify

```sh
DNSMASQ_LOG=<path>/dnsmasq.log \
HTTP_LOG=<path>/http.log \
CONSOLE_LOG=/tmp/onie-console.log \
./contrib/dhcp6-emulation/verify-dhcp6-boot.sh
```

Expected output:
```
[verify] PASS: dnsmasq sent option 59 (bootfile-url)
[verify] PASS: HTTP server served an installer/updater GET
[verify] summary: 2 passed, 0 failed
PASS
```

---

## Expected evidence

**dnsmasq log** — option 59 requested and replied:
```
requested options: 59:bootfile-url
sent size: 38 option: 59 bootfile-url  http://[2001:db8::1]:8080/onie-installer
```

**HTTP log** — installer fetched over IPv6:
```
2001:db8::xxx - - [date] "GET /onie-installer HTTP/1.1" 200 -
```

**ONIE console** — demo OS installs successfully:
```
ONIE: OS Install Mode ...
Platform  : x86_64-kvm_x86_64-r0
Version   : feature/dhcp6-boot-validation-08031432-dirty
Build Date: 2026-08-03T14:32+00:00
Info: Mounting kernel filesystems... done.
Info: Mounting ONIE-BOOT on /mnt/onie-boot ...
[    2.274131] ext4 filesystem being mounted at /mnt/onie-boot supports timestamps until 2038 (0x7fffffff)
Info: BIOS mode:   legacy
Running demonstration platform init pre_arch routines...
Running demonstration platform init post_arch routines...
Info: Making NOS install boot mode persistent.
Installing for i386-pc platform.
Installation finished. No error reported.
network_driver: Running demonstration pre_init routines...
network_driver: Running ASIC/SDK init routines...
network_driver: Running demonstration post_init routines...
Info: Using eth0 MAC address: 00:11:22:33:44:55
Info: eth0:  Checking link... up.
Info: Trying DHCPv6 on interface: eth0
udhcpc6: started, v1.25.1
udhcpc6: sending discover
udhcpc6: sending select
udhcpc6: lease obtained, lease time 3600
ONIE: Using DHCPv6 addr: eth0: 2001 / Global
fe80 / 4455/64
Starting: klogd... done.
Starting: dropbear ssh daemon... done.
Starting: telnetd... done.
discover: installer mode detected.  Running installer.
Starting: discover... done.

Please press Enter to activate this console. Info: eth0:  Checking link... up.
Info: Trying DHCPv6 on interface: eth0
ONIE: Using DHCPv6 addr: eth0: fe80 / 4455/64
2001 / Global
ONIE: Starting ONIE Service Discovery
Info: Trying bootfile URL: http://[2001:db8::1]:8080/onie-installer
Info: Attempting http://[2001:db8::1]:8080/onie-installer ...
ONIE: Executing installer: http://[2001:db8::1]:8080/onie-installer
Verifying image checksum ... OK.
Preparing image archive ... OK.
Demo Installer: platform: x86_64-kvm_x86_64-r0
Creating new demo partition /dev/vda3 ...
Warning: The kernel is still using the old partition table.
The new table will be used at the next reboot.
The operation has completed successfully.
mke2fs 1.46.3 (27-Jul-2021)
Discarding device blocks: done
Creating filesystem with 131072 1k blocks and 32768 inodes
Filesystem UUID: 1551e6e6-8930-49c6-a316-ffa16d44612e
Superblock backups stored on blocks:
        8193, 24577, 40961, 57345, 73729

Allocating group tables: done
Writing inode tables: done
Creating journal (4096 blocks): done
Writing superblocks and filesystem accounting information: done

[   48.585410] ext4 filesystem being mounted at /tmp/tmp.OplCh6 supports timestamps until 2038 (0x7fffffff)
ONIE: Unable to find 'Part Number' TLV in EEPROM data.
Success: Support tarball created: /tmp/tmp.OplCh6/onie-support-kvm_x86_64.tar.bz2
Installing for i386-pc platform.
Installation finished. No error reported.
[   49.690568] ext4 filesystem being mounted at /tmp/tmp.5Yz3ig supports timestamps until 2038 (0x7fffffff)
ONIE: NOS install successful: http://[2001:db8::1]:8080/onie-installer
ONIE: Rebooting...
```

---

## Tear down

```sh
virsh destroy onie-dhcp6
virsh undefine onie-dhcp6
sudo ./contrib/dhcp6-emulation/setup-dhcp6-test.sh down
```
