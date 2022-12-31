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
    make VERSION=1.0.0rc1 release
    ```

### Reproduce an existing release

    ```
    make VERSION=1.0.0rc1 attest
    ```

### Sign an existing release

    ```
    make VERSION=1.0.0rc1 sign
    ```

## Setup ##

1. Insert external Remote attestation key and signing key when prompted
2. Reboot and verify successful remote attestation
3. Boot to shell: Options -> Recovery Shell
4. Mount SD card
5. Insert chosen GPG Smartcard device
6. Sign target iso ```gpg --armor --detach-sign airgap*.iso```
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
