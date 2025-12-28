#!/bin/sh

set -e

PREV_DIR=$(pwd)
WORK_DIR=$(dirname -- "$0")
cd "$WORK_DIR"

cd basebin
./build.sh
cd -

rm -rf Bootstrap/basebin
cp -a basebin/.build Bootstrap/basebin

make clean
make package

cd "$PREV_DIR"
