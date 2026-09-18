#!/bin/sh
rm -Rf vendor vendor.tar.xz
cargo vendor
tar -cJ --no-xattrs -f vendor.tar.xz vendor
cp vendor/rure/include/rure.h ../rure.h
rm -Rf vendor

