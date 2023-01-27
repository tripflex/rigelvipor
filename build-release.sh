#!/usr/bin/env bash
VERSION=1.3.2

mkdir temp
cd temp
wget https://github.com/rigelminer/rigel/releases/download/$VERSION/rigel-$VERSION-linux.tar.gz
tar -xvf rigel-$VERSION-linux.tar.gz
cp rigel-$VERSION-linux/rigel ../rigelvipor/rigel
cd ..
rm -rf temp
tar -zcvf dist/rigelvipor-$VERSION.tar.gz rigelvipor
rm -rf rigelvipor/rigel