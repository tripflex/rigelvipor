#!/usr/bin/env bash

killall -9 rigel
. h-manifest.conf

./rigel $(< $CUSTOM_CONFIG_FILENAME) $@ 2>&1 | tee $CUSTOM_LOG_BASENAME.log