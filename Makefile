BUILDROOT_VERSION := 2021.08
BUILDROOT_DIR := /tmp/buildroot
ROOTFS_DIR := ./buildroot/board/dgt/centaur/rootfs_overlay
SD_CARD := /dev/mmcblk0
SD_CARD_SIZE := 16G
WPA_PRESENT := $(shell ls $(ROOTFS_DIR)/etc/wpa_supplicant.conf 2>/dev/null)
BUILDROOT_PRESENT := $(shell ls $(BUILDROOT_DIR) 2>/dev/null)
PWD := $(shell pwd)
OUTPUT_DIR := $(PWD)/_build

.PHONY: buildroot

default: build

build: init config buildroot

init:
ifeq ($(BUILDROOT_PRESENT),)
	git clone -b $(BUILDROOT_VERSION) --depth 1 git://git.buildroot.net/buildroot $(BUILDROOT_DIR)
endif

config:
ifeq ($(WPA_PRESENT),)
		echo "ctrl_interface=/var/run/wpa_supplicant" > $(ROOTFS_DIR)/etc/wpa_supplicant.conf
		echo "update_config=1" >> $(ROOTFS_DIR)/etc/wpa_supplicant.conf
		echo -n "SSID: " && read ssid && echo -n "Password: " && read psk && wpa_passphrase $$ssid $$psk | sed '/^\s*#/d ' >> $(ROOTFS_DIR)/etc/wpa_supplicant.conf
endif

buildroot:
	cd $(BUILDROOT_DIR) && make O=$(OUTPUT_DIR) BR2_EXTERNAL=$(PWD)/buildroot centaur_defconfig && make O=$(OUTPUT_DIR) BR2_EXTERNAL=$(PWD)/buildroot

flash:
	sudo dd if=$(OUTPUT_DIR)/images/sdcard.img of=$(SD_CARD) bs=1M status=progress conv=fsync
	sudo parted $(SD_CARD) resizepart 2 ${SD_CARD_SIZE}
	sudo e2fsck -f $(SD_CARD)p2
	sudo resize2fs $(SD_CARD)p2

clean:
	cd $(BUILDROOT_DIR) && make distclean
	rm -rf $(ROOTFS_DIR)/etc/wpa_supplicant.conf _build
