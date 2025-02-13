# SNK-60I0-320F

## Device and its ONIE platform identification
Please note that NOS development is based on the ONIE platform, therefore, it is very important to make sure your device's ONIE platform.

First of all, check the label on the device, the label should have the following information.
* Model
* S/N
* MAC address
* Machine Rev.
* Label Rev.

Follow the instruction to identify your device's ONIE platform in order to install ONIE on your device.
1. Check your device's **Model** belongs to SNK-60I0-320F.
2. Check your device's **Machine Rev.** and **Label Rev.** to identify the particular ONIE platform. Please refer to the below table.
3. Build the particular ONIE platform by adding option **VENDOR_REV** to compile ONIE command.
4. Use [onie-sysinfo](https://opencomputeproject.github.io/onie/cli/index.html#onie-sysinfo) to check platform name after installing ONIE on device.

| Platform name                        | Machine rev. | Label rev. | Build ONIE option |
|:------------------------------------:|:------------:|:----------:|:-----------------:|
| x86_64-alphanetworks_snk60i0_320f-r0 |  `r0`        | N/A        | VENDOR_REV=0      |

> **Label rev**. is N/A which means there is no label revision for this device.

## Build ONIE instruction
To build ONIE, change directories to *onie/build-config* at first and then type:

```
make -j4 MACHINEROOT=../machine/<vendor> MACHINE=<vendor>_<model> VENDOR_REV=<vendor_rev> all pxe-efi64
```

* \<vendor>: Hardware vendor.
* \<model>: Model name.
* \<vendor_rev>: Hardware machine revision. The default value is the latest hardware machine revision, you can specify the value to override it.

For example, to build ONIE platform **x86_64-alphanetworks_snk60i0_320f-r0** for Alpha Networks SNK-60I0-320F machine revision `r0`:

```
$ cd build-config
$ make -j4 MACHINEROOT=../machine/alphanetworks MACHINE=alphanetworks_snk60i0_320f VENDOR_REV=0 all pxe-efi64
```

For more information, please refer to [onie/machine/alphanetworks/alphanetworks_snk60i0_320f/INSTALL](https://github.com/opencomputeproject/onie/blob/master/machine/alphanetworks/alphanetworks_snk60i0_320f/INSTALL)

## Modification history
Alpha Networks uses vendor version to record Alpha Networks own ONIE software history. ONIE master branch always build the latest version ONIE images, and there is no option to build the previous version ONIE images.

| Date       | Vendor version | Description                                  |
|:----------:|:--------------:|:---------------------------------------------|
| 2025/02/13 | .alpha-0.1     | Support SNK-60I0-320F machine revision `r0`. |

