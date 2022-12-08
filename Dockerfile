FROM rclone/rclone

RUN apk update && apk add openrc

COPY sync.sh /etc/sync.sh
RUN chmod a+x /etc/sync.sh
RUN echo "* * * * * /etc/sync.sh" >> /var/spool/cron/crontabs/root

RUN printf "Init\n" > /var/log/sync.log
CMD crond -f -l 8 -L /dev/stdout

ENTRYPOINT []
