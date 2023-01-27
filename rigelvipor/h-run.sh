#!/usr/bin/env bash

killall -9 rigel
. h-manifest.conf

CUSTOM_LOG_BASEDIR=`dirname "$CUSTOM_LOG_BASENAME"`
[[ ! -d $CUSTOM_LOG_BASEDIR ]] && mkdir -p $CUSTOM_LOG_BASEDIR

# ./rigel $(< $CUSTOM_CONFIG_FILENAME) $@ 2>&1 | tee --append ${CUSTOM_LOG_BASEDIR}/${CUSTOM_LOG_BASENAME}
./rigel $(< $CUSTOM_CONFIG_FILENAME) $@ 2>&1
