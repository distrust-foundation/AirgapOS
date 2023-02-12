# AirgapOS #

<https://github.com/distrust-foundation/airgap>

## About ##

A live buildroot based Liux distribution designed for managing secrets offline.

Built for those of us that want to be -really- sure our most important secrets
are managed in a clean environment with an "air gap" between us and the
internet with high integrity on the supply chain of the firmware and OS used.

## Uses ##
 * Generate GPG keychain
 * Store/Restore gpg keychain to security token such as a Yubikey or Nitrokey
 * Signing cryptocurrency transactions
 * Generate/backup BIP39 universal cryptocurrency wallet seed
 * Store/Restore BIP39 seed to a hardware wallet such as a Trezor or Ledger

## Features ##
 * Determinsitic iso generation for multi-party code->binary verification
 * Small footprint (< 100MB)
 * Immutable and Diskless: runs from initramfs
 * Network support and most drivers removed to minimize exfiltration vectors

## Requirements ##

### Software ###

* docker 18+

### Hardware ###

* Recommended: PC running coreboot-heads
  * Allows for signed builds, and verification of signed sd card payloads
  * Ensure any Wifi/Disk/Bluetooth/Audio devices are disabled/removed
* Supported remote attestation key (Librem Key, Nitrokey, etc)
* Supported GPG smartcard device (Yubikey, Ledger, Trezor, Librem Key, etc)
* Blank flash drive
* Blank SD card

## Build ##

### Build a new release

    ```
    make release
    ```

### Reproduce an existing release

    ```
    make attest
    ```

### Sign an existing release

    ```
    make sign
    ```

## Setup ##

Assumes target is running Pureboot or Coreboot/heads

1. Boot to shell: ```Options -> Recovery Shell```
2. Mount SD card
	```
	mount-usb
	mount -o remount,rw /media
	```
3. Insert chosen GPG Smartcard device
4. Initialize smartcard
	```
	gpg --card-status
	```
5. Sign target iso
	```
	cd /media
	gpg --armor --detach-sign airgap.iso
	```
6. Unmount
	```
	cd
	umount /media
	sync
	```
7. Reboot

## Usage ##

1. Insert remote attestation device
2. Power on, and verify successful remote attestation
3. Boot to airgap via: Options -> Boot Options -> USB Boot

## Development ##

### Build develop image
```
make
```

### Boot image in qemu
```
make vm
```

### Enter shell in build environment
```
make shell
```
