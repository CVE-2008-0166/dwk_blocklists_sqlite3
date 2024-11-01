#!/bin/bash

if [ $# -eq 0 ]; then
  echo "Usage: $0 <dwk_blocklists_directory>"
  exit
fi

DBFILE="dwk_blocklists.sqlite3"
rm -f $DBFILE

TMPFILE=`mktemp`
PATTERN='([a-z0-9]+)_([a-z0-9]+)_([a-z0-9]+)'
for CSVFILE in $1/*.csv; do
  if [[ $CSVFILE =~ $PATTERN ]]; then
    echo "CREATE TABLE debian_weak_key_import ( SHA256_FINGERPRINT text );" >> $TMPFILE
    echo ".import --csv $CSVFILE debian_weak_key_import" >> $TMPFILE
    echo "CREATE TABLE debian_weak_${BASH_REMATCH[2]}_${BASH_REMATCH[3]} ( SHA256_FINGERPRINT blob NOT NULL PRIMARY KEY ) WITHOUT ROWID;" >> $TMPFILE
    echo "INSERT INTO debian_weak_${BASH_REMATCH[2]}_${BASH_REMATCH[3]} SELECT unhex(SHA256_FINGERPRINT) from debian_weak_key_import;" >> $TMPFILE
    echo "DROP TABLE debian_weak_key_import;" >> $TMPFILE
  fi
done
echo "VACUUM;" >> $TMPFILE

sqlite3 $DBFILE < $TMPFILE

rm $TMPFILE
