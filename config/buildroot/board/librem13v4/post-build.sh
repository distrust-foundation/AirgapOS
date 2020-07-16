#!/bin/sh

set -u
set -e
set -x

BOARD_DIR="$(dirname $0)"

cp -f ${BOARD_DIR}/grub.cfg ${TARGET_DIR}/boot/grub/grub.cfg

exit $?
