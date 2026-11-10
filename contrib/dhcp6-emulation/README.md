# DHCPv6 (RFC 5970) Boot Validation Harness

Validates the ONIE DHCPv6 installer-discovery path end-to-end on
`kvm_x86_64`, without hardware:

1. `udhcpc6` requests RFC 5970 option 59 (Boot File URL)
2. a DHCPv6 server (dnsmasq) replies with the installer URL
3. ONIE discovers `onie_disco_bootfile` and fetches the installer
   over IPv6

This test reuses the stock ONIE build flow
(`contrib/build-env`) and adds only what QEMU user-mode networking
cannot provide: a real L2 segment with a real DHCPv6 server (QEMU's
built-in SLIRP networking is IPv4-only DHCP; it cannot serve DHCPv6
option 59). For the full UEFI/ISO/Secure-Boot VM flow, use the
existing `emulation/onie-vm.sh` instead — this harness intentionally
does not duplicate it.

Requires a Linux host with root (network namespaces), `dnsmasq`,
`python3`, `iproute2`, and QEMU.

## Layout

    setup-dhcp6-test.sh   Create netns + bridge + tap, start dnsmasq
                          (DHCPv6, option 59) and an HTTP server
    run-onie-vm.sh        Boot the built ONIE kernel+initrd in QEMU on
                          the tap interface (direct -kernel boot). It is
                          optional to create an image file with a flag `--with-disk`
                          if you want to see the demo OS gets installed after discovery.
    verify-dhcp6-boot.sh  PASS/FAIL gate: check dnsmasq log for
                          option 59, HTTP log for the installer GET,
                          optionally the captured console log
    test-udhcp6-sd.sh     Hermetic micro-test: prove udhcp6_sd maps
                          option 59 (bootfile=) to onie_disco_bootfile.
                          No network, no VM, runs in well under a
                          second, anywhere.

## Quick start

Build ONIE in the stock container build environment (see
`contrib/build-env/README.md`):

    # inside the build-env container
    cd onie/build-config
    make MACHINE=kvm_x86_64 signing-keys-generate   # once, if unset
    make MACHINE=kvm_x86_64 shim-self-sign
    make MACHINE=kvm_x86_64 -j4 all demo

This harness boots the kernel directly
(`qemu -kernel/-initrd`), so firmware signature verification is never
involved and the stock Secure-Boot-enabled machine configuration works
unchanged.

Set up the test network and payload (on the QEMU host):

    cd onie/contrib/dhcp6-emulation
    mkdir /tmp/payload
    cp ../../build/images/demo-installer-x86_64-kvm_x86_64-r0.bin /tmp/payload/onie-installer
    sudo ./setup-dhcp6-test.sh up        # 'down' tears everything down

Boot ONIE and capture the console:

    sudo ./run-onie-vm.sh 2>&1 | tee console.log        # exit QEMU: Ctrl-a x

To also exercise install-to-disk (fetch + checksum + extract + install
to `/dev/vda`), attach a qcow2 disk:

    sudo ./run-onie-vm.sh --with-disk 2>&1 | tee console.log
    # bootstrap is deterministic: ANY EXISTING FILE AT PATH IS
    # DELETED and a fresh disk with GRUB-BOOT (ef02) and ONIE-BOOT
    # (ext4, labeled) partitions + minimal grub scaffolding is built
    # via qemu-nbd each run.  Default disk:
    # /tmp/onie-disk-kvm_x86_64.qcow2; pass --with-disk PATH to
    # override, DISK_SIZE=... to change size (default 4G).

If you exercised with the option `--with-disk`, it is expected to see output
demonstrating the success of image discovery via DHCPv6:

```
Please press Enter to activate this console. Info: eth0:  Checking link... up.
ONIE: Using link-local IPv4 addr: eth0: 169.254.4.4/16
Info: Trying DHCPv6 on interface: eth0
ONIE: Using DHCPv6 addr: eth0: 2001:db8::17d
ONIE: Starting ONIE Service Discovery
Info: Attempting http://[2001:db8::1]:8080/onie-installer ...
ONIE: Executing installer: http://[2001:db8::1]:8080/onie-installer
Verifying image checksum ... OK.
Preparing image archive ... OK.
Demo Installer: platform: x86_64-kvm_x86_64-r0
Creating new demo partition /dev/vda3 ...
Warning: The kernel is still using the old partition table.
The new table will be used at the next reboot.
The operation has completed successfully.
```

Without `--with-disk` the harness boots diskless: DHCPv6 fetch and
installer verification succeed, but the demo installer's block-device
step is expected to fail (no disk) — sufficient to validate the DHCPv6
discovery path itself.

Verify the evidence chain:

    CONSOLE_LOG=console.log sudo ./verify-dhcp6-boot.sh

Expected result: dnsmasq logged sending option 59, the HTTP server
served the installer, and the console shows `onie_disco_bootfile`
(two PASS lines).

Kernel/initrd paths, machine name, tap name, and memory can be
overridden via environment variables; see the headers of
`run-onie-vm.sh` and `setup-dhcp6-test.sh`.

## Kernel cmdline: `dhcp_type`

ONIE's DHCPv4 and DHCPv6 management-interface configuration and
discovery are gated by the `dhcp_type` kernel cmdline value,
exported internally as `$onie_dhcp_type`:

| Value       | DHCPv4 | DHCPv6 |
|-------------|:------:|:------:|
| `no`        |   —    |   —    |
| `ipv4_only` |   ✓    |   —    |
| `ipv6_only` |   —    |   ✓    |
| `ipv4_ipv6` |   ✓    |   ✓    |

Default is `ipv4_only` so no v4-only deployment pays a DHCPv6-wait
cost at boot.  This harness defaults to `ipv6_only` so no extra cmdline is needed on the bench; override with
`ONIE_DHCP_TYPE=ipv4_ipv6 ./run-onie-vm.sh …`.

In dual-stack where both DHCPv4 option 67 and DHCPv6 option 59 are
advertised, the DHCPv4 value wins — `sd_dhcp4` appends to
`onie_disco` after `sd_dhcp6` and overrides.

## Limitations

* busybox udhcpc6 exports the leased address without a prefix length
  (DHCPv6 itself carries no prefix), so ONIE installs it as a /128
  host address and no IPv6 default route is configured.  The installer
  server must be on-link.  That is why this harness puts dnsmasq and
  the HTTP server on the same L2 segment as the ONIE VM.
* busybox `option_to_env()` stops parsing options whose code or length
  exceeds 255 (pre-existing behavior); a Boot File URL longer than
  255 bytes truncates parsing of the remaining options.
