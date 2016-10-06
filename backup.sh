#!/bin/bash
#
# Argument = -u user -p password -k key -s secret -b bucket
#
# To Do - Add logging of output.
# To Do - Abstract bucket region to options
echo "Running backup..."
. /root/project_env.sh
set -e

export PATH="$PATH:/usr/local/bin"

usage()
{
cat << EOF
usage: $0 options

This script dumps the current mongo database, tars it, then sends it to an Amazon S3 bucket. Environment variable is used as parameters.

Options:
   -h      Show this message
Variables:
   MONGODB_HOST        Mongodb node host (defaults to localhost)
   MONGODB_USER        Mongodb user (optional)
   MONGODB_PASSWORD    Mongodb password (optional)
   AWS_ACCESS_KEY      AWS Access Key
   AWS_SECRET_KEY      AWS Secret Key
   S3_REGION           Amazon S3 region
   S3_BUCKET           Amazon S3 bucket name
EOF
}

MONGODB_HOST=${MONGODB_HOST:-localhost}

while getopts “h” OPTION
do
  case $OPTION in
    h)
      usage
      exit 1
      ;;
  esac
done

if [[ -z $AWS_ACCESS_KEY ]] || [[ -z $AWS_SECRET_KEY ]] || [[ -z $S3_REGION ]] || [[ -z $S3_BUCKET ]]
then
  usage
  exit 1
fi

# Get the directory the script is being run from
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# Store the current date in YYYY-mm-DD-HHMMSS
DATE=$(date -u "+%F-%H%M%S")
FILE_NAME="backup-$DATE"
ARCHIVE_NAME="$FILE_NAME.tar.gz"

# Lock the database
# Note there is a bug in mongo 2.2.0 where you must touch all the databases before you run mongodump

if [[ ! -z $MONGODB_HOST ]]
then
  MONGODB_HOST="localhost"
fi
if [[ ! -z $MONGODB_USER ]] && [[ ! -z $MONGODB_PASSWORD ]]
then
  mongo -username "$MONGODB_USER" -password "$MONGODB_PASSWORD" "$MONGODB_HOST/admin" --eval "var databaseNames = db.getMongo().getDBNames(); for (var i in databaseNames) { printjson(db.getSiblingDB(databaseNames[i]).getCollectionNames()) }; printjson(db.fsyncLock());"

  # Dump the database
  mongodump -username "$MONGODB_USER" -password "$MONGODB_PASSWORD" -host "$MONGODB_HOST" --out $DIR/backup/$FILE_NAME

  # Unlock the database
  mongo -username "$MONGODB_USER" -password "$MONGODB_PASSWORD" "$MONGODB_HOST/admin" --eval "printjson(db.fsyncUnlock());"
else
  mongo "$MONGODB_HOST/admin" --eval "var databaseNames = db.getMongo().getDBNames(); for (var i in databaseNames) { printjson(db.getSiblingDB(databaseNames[i]).getCollectionNames()) }; printjson(db.fsyncLock());"

  # Dump the database
  mongodump --host "$MONGODB_HOST" --out $DIR/backup/$FILE_NAME

  # Unlock the database
  mongo "$MONGODB_HOST/admin" --eval "printjson(db.fsyncUnlock());"
fi

# Tar Gzip the file
tar -C $DIR/backup/ -zcvf $DIR/backup/$ARCHIVE_NAME $FILE_NAME/

# Remove the backup directory
rm -r $DIR/backup/$FILE_NAME

# Send the file to the backup drive or S3

export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY
export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_KEY
export AWS_DEFAULT_REGION=$S3_REGION

aws s3 cp $DIR/backup/$ARCHIVE_NAME s3://$S3_BUCKET/$ARCHIVE_NAME
rm $DIR/backup/$ARCHIVE_NAME

echo "Backup finished!"

