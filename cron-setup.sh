echo "${CRON_EXPRESSION} sh /mongodb-s3-backup/backup.sh > `tty`" | crontab -
printenv | sed 's/^\(.*\)$/export "\1"/g' > /root/project_env.sh
cron reload
echo "Crontab has been setup."
tail -f /dev/null