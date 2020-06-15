# Airgap #

<https://gitlab.com/pchq/airgap>

## About ##

A live buildroot based distribution designed for managing secrets offline.

Built for those of us that want to be -really- sure our most important secrets
are managed in a clean environment with an "air gap" between us and the
internet.

## Use Cases ##

- Generate GPG keychain
- Store/Restore gpg keychain to security token such as a Yubikey or Nitrokey
- Signing cryptocurrency transactions
- Generate/backup BIP39 universal cryptocurrency wallet seed
- Store/Restore BIP39 seed to a hardware wallet such as a Trezor or Ledger

## Requirements ##

### Software ###

* docker 18+

### Hardware ###

* Any x86_64 laptop known to support Linux should work.
* Ideally use a coreboot compatible machine with Heads for secure boot
* Ensure any Wifi/Bluetooth/Audio devices are removed

## Build ##

```
make all
```

## Install ##

TBD

## Development ##

### Boot image in qemu

```
make vm
```
