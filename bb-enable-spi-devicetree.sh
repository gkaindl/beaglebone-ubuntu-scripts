#!/bin/sh
#
# This script modifies the flattened device-tree blob used by uboot on 3.8 and
# later kernels for BeagleBone (Black) to enable SPI1 and export the first
# chip-select line (cs0) as spidev device. The pinmux settings will also be
# set. After running this script, a reboot is required to load the modified
# device-tree.
#
# It should work on BeagleBone/Ubuntu, but might also work on other distros.
#

FDT_SPI_DEV="spi@481a0000"

UBOOTBASE="/boot/uboot"
FDTBASE="${UBOOTBASE}/dtbs"
FDT_SPI_PATH="/ocp/${FDT_SPI_DEV}"

REBOOT_REQUIRED=""

notif () {
   echo "\033[1;34m${1}\033[0m${2}"
}

fail () {
   echo "\033[1;31m${1}\033[0m${2}"
   exit 0
}

checks () {
   if ! [ $(id -u) = 0 ]; then
      fail "you need to be root to run this (or use sudo)."
   fi
   
   has_fdttools=$(which fdtget 2>/dev/null)
   if [ ! "${has_fdttools}" ]; then
      fail "you need to install the device tree tools (apt-get install device-tree-compiler)."
   fi
}

find_devicetree_file () {
   FDT=$(strings "${UBOOTBASE}/u-boot.img" 2>/dev/null | grep fdtfile= | sed -nE 's/fdtfile=(.*)$/\1/p')
   
   if [ -z ${FDT} ]; then
      fail "failed to extract flattened device-tree file from " "${UBOOTBASE}/u-boot.img"
   fi
   
   if [ ! -f "${FDTBASE}/${FDT}" ]; then
      fail "flattened device-tree file cannot be found at " "${FDTBASE}/${FDT}"
   else
      notif "found flattened device-tree at " "${FDTBASE}/${FDT}"
   fi
}

enable_spi () {
   SPISTATUS=$(fdtget "${FDTBASE}/${FDT}" "${FDT_SPI_PATH}" status 2>&1)
   
   if [ "${SPISTATUS}" != "${SPISTATUS#*FDT_ERR_NOTFOUND}" ]; then
      fail "path to spi device not found in flattened device-tree: " "${FDT_SPI_PATH}"
   fi
   
   if [ "${SPISTATUS}" = "okay" ]; then
      notif "spi device at ${FDT_SPI_PATH} is already enabled, nothing to do."
   else   
      fdtput -t s "${FDTBASE}/${FDT}" "${FDT_SPI_PATH}" "status" "okay" 2>&1
      
      SPISTATUS=$(fdtget "${FDTBASE}/${FDT}" "${FDT_SPI_PATH}" status 2>&1)
      
      if [ "${SPISTATUS}" != "okay" ]; then
         fail "failed to enable spi device at ${FDT_SPI_PATH}. status is now: " ${SPISTATUS}
      else
         notif "successfully enabled " ${FDT_SPI_PATH}
         REBOOT_REQUIRED="yes"
      fi
   fi
}

enable_spi_dev () {
   SPIDEVSTATUS=$(fdtget "${FDTBASE}/${FDT}" "${FDT_SPI_PATH}/spidev@0" reg 2>&1)
   
   if [ "${SPIDEVSTATUS}" = "${SPIDEVSTATUS#*FDT_ERR_NOTFOUND}" ]; then
      notif "spidev at ${FDT_SPI_PATH}/spidev@0 already present, nothing to do."
   else
      FDTTEMP=$(mktemp -u)
      DTSTEMP=$(mktemp -u)
      DTSTEMP2=$(mktemp -u)
      
      dtc -I dtb -O dts -o "${FDTTEMP}" "${FDTBASE}/${FDT}"
      
      cat "${FDTTEMP}" | perl -ne "if (\$f>0 && /\};\$/) { print \"\n};\npinmux_spi1_pins \{\npinctrl-single,pins = <0x190 0x13 0x194 0x33 0x198 0x13 0x19c 0x13 0x164 0x12>;\nlinux,phandle = <0x12>;\nphandle = <0x12>;\n};\n\n\"; \$f=0; } else { print; } \$f=1 if (/pinmux_userled_pins {/)" > "${DTSTEMP}"
      cat "${DTSTEMP}" | perl -ne "if (\$f>0 && /\};\$/) { print \"\npinctrl-0 = <0x12>;\nspidev: spidev\@0 \{\ncompatible = \\\"linux,spidev\\\";\nreg = <0>;\nspi-max-frequency = <24000000>;\n};\n};\n\n\"; \$f=0; } else { print; } \$f=1 if (/${FDT_SPI_DEV} {/)" > "${DTSTEMP2}"
      
      dtc -I dts -O dtb -o "${FDTBASE}/${FDT}" ${DTSTEMP2}
      
      rm -f "${FDTTEMP}"
      rm -f "${DTSTEMP}"
      rm -f "${DTSTEMP2}"
      
      SPIDEVSTATUS=$(fdtget "${FDTBASE}/${FDT}" "${FDT_SPI_PATH}/spidev@0" reg 2>&1)
      
      if [ "0" = "${SPIDEVSTATUS}" ]; then
         notif "successfully enabled " "${FDT_SPI_PATH}/spidev@0"
         REBOOT_REQUIRED="yes"
      else
         fail "failed to enable " "${FDT_SPI_PATH}/spidev@0"
      fi
   fi
}

checks
find_devicetree_file
enable_spi
enable_spi_dev

if [ "yes" = "${REBOOT_REQUIRED}" ]; then
   notif "please reboot."
fi

