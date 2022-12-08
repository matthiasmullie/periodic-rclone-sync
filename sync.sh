#!/bin/sh

LOG=/var/log/sync.log

if [ "$(($(date +%s) / 60 % ${INTERVAL}))" -eq "0" ]
then
  rclone sync ${SOURCE} ${TARGET}
  printf "Syncing ${SOURCE} to ${TARGET} complete\n" > ${LOG}
  cat ${LOG}
fi
