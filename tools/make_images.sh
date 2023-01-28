#!/bin/bash

SOC=$1
OPENIPC_FLAVOR=$2 # lite, utlimate
FLASH="8MB" # 8MB, 16MB

### FIXME: when we needed and what parameters are adjustable?
#CMA="--cma 'mmz=anonymous,0,0x42000000,96M mmz_allocator=cma'"

# --- You don't need to edit anything below this line, unless you have to. --- #

### constants

DL_URL=https://github.com/OpenIPC/firmware/releases/download/latest
OUTPUT_DIR=output
TEMP_DIR=$(mktemp -d)
VALID_SOCS="s2l22m s2l33m s3l ak3916ev300 ak3918ev300 fh8833v100 fh8852v100
fh8852v200 fh8852v210 fh8856v100 fh8856v200 fh8856v210 fh8858v200 fh8858v210
gk7102 gk7102s gk7202v300 gk7205v200 gk7205v210 gk7205v300 gk7605v100 gm8135
gm8136 hi3516av100 hi3516av200 hi3516av300 hi3516cv100 hi3516cv200 hi3516cv300
hi3516cv500 hi3516dv100 hi3516dv200 hi3516dv300 hi3516ev100 hi3516ev200
hi3516ev300 hi3518cv100 hi3518ev100 hi3518ev200 hi3518ev201 hi3518ev300
hi3519v101 hi3520dv200 hi3536cv100 hi3536dv100 t10 t20 t21 t30 t31 nt98562
nt98566 rv1109 rv1126 msc313e msc316dc msc316dm ssc325 ssc333 ssc335 ssc335de
ssc337 ssc337de xm510 xm530 xm550"
VALID_OPENIPC_FLAVORS="lite ultimate"
VALID_T31_FLAVORS="a al l n x"

### functions

echo_c() {
  # 30 grey, 31 red, 32 green, 33 yellow, 34 blue, 35 magenta, 36 cyan, 37 white
  echo -e "\e[1;$1m$2\e[0m"
}

debug() {
  [ "0$DEBUG" -gt "0" ] && echo_c 35 "$1"
}

die() {
  echo_c 31 "$1"
  exit ${2:-99}
}

mkdir_p() {
  [ ! -d $1 ] && mkdir -p $1
}

print_usage() {
  echo "Usage: $0 <soc> <openipc flavor> [<t31 flavor>]"
  echo "Where openipc flavor is one of [${VALID_OPENIPC_FLAVORS}]."
  echo "And t31 flavor is one of [${VALID_T31_FLAVORS}], only for t31 soc."
}

### business logic

if [ "$OPENIPC_FLAVOR" == "ultimate" ]; then
  FLASH="16MB"
fi

if [ -z "$SOC" ]; then
  print_usage
  exit 1
fi

if ! echo $VALID_SOCS | grep -qE "\b${SOC%_*}\b"; then
  die "${SOC} is not a valid SoC!" 2
fi

if [ -z "$OPENIPC_FLAVOR" ]; then
  print_usage
  exit 1
fi

if ! echo $VALID_OPENIPC_FLAVORS | grep -qE "\b${OPENIPC_FLAVOR%_*}\b"; then
  die "${OPENIPC_FLAVOR} is not a valid OpenIPC Flavor!" 2
fi

FULL_PATH=$(find ../../openipc-firmware/br-ext-chip-* -name "${SOC}_${OPENIPC_FLAVOR}_defconfig")
if [ -z "$FULL_PATH" ]; then
  die "Cannot find anything for ${SOC}" 3
fi

if [ "$(echo ${FULL_PATH} | wc -w)" -gt "1" ]; then
  die "Found multiple options for ${SOC}: ${FULL_PATH}" 4
fi



FAMILY=$(grep "BR2_LINUX_KERNEL_CUSTOM_CONFIG_FILE" ${FULL_PATH} | head -1 | cut -d "/" -f 3)

### FIXME: Do we need this reassigning?
SOC=$(grep "BR2_LINUX_KERNEL_CUSTOM_CONFIG_FILE" ${FULL_PATH} | head -1 | cut -d "/" -f 5 | cut -d "." -f 1)

BOOT="$SOC"
### FIXME: Ingenic T31 family has five bootloaders to chose from.
### There should be a better way to do that.
if [ "t31" = "$BOOT" ]; then
  if [ -z "$4" ]; then
    print_usage
    die "T31 SoC requires an additional parameter for bootloader."
  else
    BOOT="${BOOT}${3}"
  fi
fi

echo "FULL_PATH: ${FULL_PATH}"
echo "SOC: ${SOC}"
echo "OPENIPC_FLAVOR: ${OPENIPC_FLAVOR}"
echo "FAMILY: ${FAMILY}"
echo "BOOT: ${BOOT}"
echo "FLASH: ${FLASH}"

echo_c 37 "Download bootloader"
echo " - ${DL_URL}/u-boot-${BOOT}-universal.bin"
wget --quiet --directory-prefix=${TEMP_DIR} ${DL_URL}/u-boot-${BOOT}-universal.bin

echo_c 37 "Download firmware"
echo " - ${DL_URL}/openipc.${SOC}-nor-${OPENIPC_FLAVOR}.tgz"
wget --quiet --output-document=- ${DL_URL}/openipc.${SOC}-nor-${OPENIPC_FLAVOR}.tgz \
  | tar xfz - --directory=${TEMP_DIR}

echo_c 37 "Create ${OUTPUT_DIR}/upgrade.${SOC} bundle using"
echo " - ${TEMP_DIR}/u-boot-${BOOT}-universal.bin"
echo " - ${TEMP_DIR}/uImage.${SOC}"
echo " - ${TEMP_DIR}/rootfs.squashfs.${SOC}"

mkdir_p ${OUTPUT_DIR}

./upgrade_bundle.py \
  --boot ${TEMP_DIR}/u-boot-${BOOT}-universal.bin \
  --kernel ${TEMP_DIR}/uImage.${SOC} \
  --rootfs ${TEMP_DIR}/rootfs.squashfs.${SOC} \
  --flash ${FLASH} \
  -i -o ${OUTPUT_DIR}/upgrade.${SOC} # --pack ${CMA}

rm -r ${TEMP_DIR}

echo_c 32 "Done\n"

exit 0
