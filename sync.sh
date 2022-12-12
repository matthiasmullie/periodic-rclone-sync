#!/bin/sh

LOG=/var/log/sync.log

if [ "$(($(date +%s) / 60 % ${INTERVAL}))" -eq "0" ]
then
  rclone sync ${SOURCE} ${TARGET} ${OPTIONS} > ${LOG} && printf "periodic-rclone-sync complete: ${SOURCE} to ${TARGET}\n" >> ${LOG}
  cat ${LOG}
fi
