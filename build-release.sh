#!/usr/bin/env bash
RIGEL_VERSION=1.3.2
THIS_VERSION=h2

RELEASE_VERSION="${RIGEL_VERSION}_${THIS_VERSION}"

rm -rf dist/rigelvipor-$RELEASE_VERSION.tar.gz
mkdir temp
cd temp
wget https://github.com/rigelminer/rigel/releases/download/$RIGEL_VERSION/rigel-$RIGEL_VERSION-linux.tar.gz
tar -xvf rigel-$RIGEL_VERSION-linux.tar.gz
cp rigel-$RIGEL_VERSION-linux/rigel ../rigelvipor/rigel
cd ..
rm -rf temp


tar -zcvf dist/rigelvipor-$RELEASE_VERSION.tar.gz rigelvipor
rm -rf rigelvipor/rigel