# MongoDB to Amazon S3 Backup Script

The backup script is based on (webcast-io's repo)[https://github.com/webcast-io/docker-mongodb-s3-backup]

## Features
- Backups all MongoDB databases to Amazon S3
- Built-in cron task
- Support database that requires no auth

## Usage
```
docker run -d
--name mongodb-s3-backup \
--env AWS_ACCESS_KEY=<KEY> \
--env AWS_SECRET_KEY=<SECRET> \
--env S3_REGION=<REGION> \
--env S3_BUCKET=<BUCKET_NAME> \
--env CRON_EXPRESSION="0 0 * * *" \
takemetour/mongodb-s3-backup
```
