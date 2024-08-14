#!/bin/sh

set -e

PREV_DIR=$(pwd)
WORK_DIR=$(dirname -- "$0")
cd "$WORK_DIR"

cd basebin
./rebuild.sh
cd -

make clean
make package

cd "$PREV_DIR"
