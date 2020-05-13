VIVADO_VERSION 			?= 2019.2
CROSS_COMPILE  			?= arm-linux-gnueabihf-
DEVICE_TREE_INCLUDE ?= zynq-7000

TOOLCHAIN = $(shell which $(CROSS_COMPILE)gcc)
TOOLCHAIN2= $(shell dirname $(TOOLCHAIN))
TOOLCHAIN_PATH = $(shell dirname $(TOOLCHAIN2))
NCORES = $(shell grep -c ^processor /proc/cpuinfo)
VIVADO_SETTINGS ?= /opt/Xilinx/Vivado/$(VIVADO_VERSION)/settings64.sh
VSUBDIRS = buildroot linux u-boot-xlnx

build:
	mkdir -p $@

build/hwdef:
	mkdir -p $@

build/device-tree:
	mkdir -p $@

%: build/%d
	cp $< $@

### u-boot ###

u-boot-xlnx/u-boot u-boot-xlnx/tools/mkimage:
	make -j$(NCORES) -C u-boot-xlnx ARCH=arm zynq_coraz7_defconfig
	make -j$(NCORES) -C u-boot-xlnx ARCH=arm CROSS_COMPILE=$(CROSS_COMPILE)

.PHONY: u-boot-xlnx/u-boot

build/u-boot.elf: u-boot-xlnx/u-boot | build
	cp $< $@

### linux ###

linux-xlnx/arch/arm/boot/zImage:
	make -C linux-xlnx ARCH=arm xilinx_zynq_defconfig
	make -C linux-xlnx -j $(NCORES) ARCH=arm CROSS_COMPILE=$(CROSS_COMPILE) zImage UIMAGE_LOADADDR=0x8000

.PHONY: linux-xlnx/arch/arm/boot/zImage

build/zImage: linux-xlnx/arch/arm/boot/zImage | build
	cp $< $@

# linux/arch/arm/boot/zImage:
# 	make -C linux ARCH=arm multi_v7_defconfig
# 	make -C linux -j $(NCORES) ARCH=arm CROSS_COMPILE=$(CROSS_COMPILE) zImage UIMAGE_LOADADDR=0x8000
#
# .PHONY: linux/arch/arm/boot/zImage
#
# build/zImage: linux/arch/arm/boot/zImage | build
# 	cp $< $@

### device tree ###

build/zynq.dtb: build/device-tree
	#bash -c "cd hdl && xsct get_device_tree.tcl"
	cpp -nostdinc -I include -I arch -undef -x assembler-with-cpp hdl/system-top.dts hdl/system-top.dts.preprocessed
	#cpp -nostdinc -I include -I arch -undef -x assembler-with-cpp u-boot-xlnx/arch/arm/dts/zynq-coraz7.dts hdl/system-top.dts.preprocessed
	dtc -O dtb -o $@ hdl/system-top.dts.preprocessed

### buildroot ###

buildroot/output/images/rootfs.cpio.gz:
	make -C buildroot ARCH=arm zynq_defconfig
	make -C buildroot TOOLCHAIN_EXTERNAL_INSTALL_DIR=$(TOOLCHAIN_PATH) ARCH=arm CROSS_COMPILE=$(CROSS_COMPILE) all

.PHONY: buildroot/output/images/rootfs.cpio.gz

build/rootfs.cpio.gz: buildroot/output/images/rootfs.cpio.gz | build
	cp $< $@

### Hardware Defintions ###

build/hwdef/system_top.xsa: build/hwdef
	bash -c "source ${VIVADO_SETTINGS} && cd hdl && vivado -mode batch -source build_hdl_project.tcl -notrace -nolog -nojournal && cd .."
	cp hdl/design_1_wrapper.xsa $@

build/system_top.bit: build/hwdef/system_top.xsa | build/hwdef
	cp hdl/design_1_wrapper.bit $@

build/fsbl.elf: build/hwdef/system_top.xsa | build/hwdef
	bash -c "source $(VIVADO_SETTINGS) && cd hdl && xsct build_fsbl.tcl"
	cp hdl/fsbl.elf $@

build/image.ub: u-boot-xlnx/tools/mkimage build/zImage build/rootfs.cpio.gz build/system_top.bit build/zynq.dtb
	u-boot-xlnx/tools/mkimage -f scripts/zynq.its $@

build/boot.bin: build/fsbl.elf build/system_top.bit build/u-boot.elf
	echo img:{[bootloader] $^} > build/boot.bif
	bash -c "source $(VIVADO_SETTINGS) && bootgen -image build/boot.bif -w -o $@"

### Utilities ###
build/uImage: build/zImage u-boot-xlnx/tools/mkimage
	u-boot-xlnx/tools/mkimage -A arm -O linux -T kernel -C none -a 0x00008000 -e 0x00008000 -n "Linux Kernel" -d build/zImage $@

build/uramdisk.image.gz: build/rootfs.cpio.gz u-boot-xlnx/tools/mkimage
	u-boot-xlnx/tools/mkimage -A arm -T ramdisk -C gzip -d build/rootfs.cpio.gz $@

build/devicetree.dtb: build/zynq.dtb
	cp $< $@
