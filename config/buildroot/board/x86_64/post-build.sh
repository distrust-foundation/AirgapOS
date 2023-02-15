#!/bin/sh

set -u
set -e
set -x

BOARD_DIR="$(dirname $0)"

cp -f ${BOARD_DIR}/grub.cfg ${TARGET_DIR}/boot/grub/grub.cfg

echo "export VERSION=\"${VERSION}\"" > ${TARGET_DIR}/etc/environment
echo "export GIT_REF=\"${GIT_REF}\"" > ${TARGET_DIR}/etc/environment
echo "export GIT_AUTHOR=\"${GIT_AUTHOR}\"" >> ${TARGET_DIR}/etc/environment
echo "export GIT_KEY=\"${GIT_KEY}\"" >> ${TARGET_DIR}/etc/environment
echo "export GIT_TIMESTAMP=\"${GIT_TIMESTAMP}\"" >> ${TARGET_DIR}/etc/environment

exit $?
