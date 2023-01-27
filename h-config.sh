#!/usr/bin/env bash
# This code is included in /hive/bin/custom function

echo -e "--algorithm $CUSTOM_ALGO --url stratum+tcp://$CUSTOM_URL --username $CUSTOM_TEMPLATE $CUSTOM_USER_CONFIG" > $CUSTOM_CONFIG_FILENAME