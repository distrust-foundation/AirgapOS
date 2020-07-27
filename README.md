# AirgapOS #

<https://gitlab.com/pchq/airgap>

## About ##

A live buildroot based distribution designed for managing secrets offline.

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
 * Builds Coreboot-heads firmware for all supported devices for measured boot
 * Determinsitic rom/iso generation for multi-party code->binary verification
 * Small footprint (< 100MB)
 * Immutable and Diskless: runs from initramfs
 * Network support and most drivers removed to minimize exfiltration vectors

## Supported Devices ##

  | Device      | TPM Model      | TPM Version | Remote Attestation  |
  |-------------|:--------------:|:-----------:|:-------------------:|
  | Librem13v4  | Infineon 9465  | 1.2         | HOTP via Nitrokey   |
  | Librem15v4  | Infineon 9456  | 1.2         | HOTP via Nitrokey   |

## Requirements ##

### Software ###

* docker 18+

### Hardware ###

* Supported PC already running coreboot-heads
  * Ensure any Wifi/Disk/Bluetooth/Audio devices are removed
* Supported remote attestation key (Librem Key, Nitrokey, etc)
* Supported GPG smartcard device (Yubikey, Ledger, Trezor, Librem Key, etc)
* Blank flash drive
* Blank SD card


## Build ##

1. Reproduce existing release, or build fresh if never released:

    ```
    make VERSION=1.0.0rc1
    ```

2. Compares hashes of newly built iso/rom files with in-tree hashes.txt

    ```
    make VERSION=1.0.0rc1 verify
    ```


## Install ##

1. Place contents of release/$VERSION folder on SD card
2. Boot machine to Heads -> Options -> Flash/Update BIOS
3. Flash firmware via "Flash the firmware with new ROM, erase settings"
4. Insert external Remote attestation key and signing key when prompted
6. Reboot and verify successful remote attestation
7. Boot to shell: Options -> Recovery Shell
8. Mount SD card
9. Insert chosen GPG Smartcard device
10. Sign target iso ```gpg --armor --detach-sign airgap*.iso```
11. Reboot


## Usage ##

1. Insert remote attestation device
2. Power on, and verify successful remote attestation
3. Boot to airgap via: Options -> Boot Options -> USB Boot


## Release ##

1. Audit dependencies to ensure no relevant CVEs are open at the moment:

    ```
    make audit
    ```

2. Verify and add detached signature to given release with:

    ```
    make VERSION=1.0.0rc1 verify sign
    ```

3. Commit signatures.


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
