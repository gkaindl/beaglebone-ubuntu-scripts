# Beaglebone Ubuntu Scripts

A collection of scripts that are probably useful if you are playing with Ubuntu on a Beaglebone (Black). I use these not only to automate tasks, but also as a knowledge repository.

## bb-enable-spi-devicetree

This script modifies the flattened device-tree blob used by uboot on 3.8 and later kernels for BeagleBone (Black) to enable SPI1 and export the first chip-select line (cs0) as spidev device. The pinmux settings will also be set. After running this script, a reboot is required to load the modified device-tree.

It should work on BeagleBone/Ubuntu, but might also work on other distros.

## bb-get-rcn-kernel-source

This script downloads, patches and prepares the kernel sources for BeagleBone (Black) kernels distributed by http://rcn-ee.net in order to enable you to compile kernel modules right on the BeagleBone: After installing the kernel sources with this script, you should be able to build kernel modules via their respective makefile.

Note that this will only work for those kernels for which rcn-ee has a kernel-headers package as well – This should be the case for most older and some newer kernels, but there was a time where the kernel-headers package was missing from the distributions. The script will notify you if you want to run it for a kernel for which no kernel-headers package is available.

By default, the script will prepare the sources for the currently running kernel. However, you can also specify a different kernel version as the first script argument, e.g. `./bb-get-rcn-kernel-source.sh 3.8.13-bone19`

Also, please edit the DIST variable at the top of the script to match the distribution you are running.

Oh, and also ensure that you have all the necessary dependencies installed, since the script doesn't check: gcc, make and all the usual suspects for building kernel-related things.

I've only tested this on Ubuntu, but it should probably also work with Debian.

## bb-show-serial

This script reads the serial number from the i2c-connected eeprom available on BeagleBone (Black). It should work both on device-tree and pre-device-tree kernels.

The serial number is unique for each BeagleBone (Black) and also includes the week/year of manufacture in the first 4 digits.

I only tested this on Ubuntu, but it should probably work on other distros as well.
