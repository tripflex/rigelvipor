#!/usr/bin/env bash
# This code is included in /hive/bin/custom function
conf=" --algorithm $CUSTOM_ALGO --url stratum+tcp://pool.vipor.net:$CUSTOM_URL --username $CUSTOM_TEMPLATE --api-bind 0.0.0.0:5000 --no-tui --log-file $CUSTOM_LOG_BASENAME.log"
[[ ! -z $CUSTOM_USER_CONFIG ]] && conf+=" $CUSTOM_USER_CONFIG"

echo "$conf"
echo "$conf" > $CUSTOM_CONFIG_FILENAME
