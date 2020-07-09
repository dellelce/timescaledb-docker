#!/bin/sh

## ENVIRONMENT ##

# this should be automatically detected from the build (not environment?)
export POSTGRES_USER=pg

## FUNCTIONS ##

generate_password()
{
 pwgen -ysc -r "\`" 16 1
}

hba_setup()
{
 echo "host all all all md5" >> ${PGDATA}/pg_hba.conf
}

pg_setup()
{
 local INTERNAL_USER="postgres"
 local PWFILE="pw.${RANDOM}${RANDOM}"

 chmod 750 ${PGDATA}
 chown "${POSTGRES_USER}" "${PGDATA}"

 ls -ltd "${PGDATA}"

 # print the password to the "log" if we need to generate it and there is nowhere else to write
 [ -z "$POSTGRES_PASSWORD" ] &&
 {
   export POSTGRES_PASSWORD=$(generate_password)
   # we now have a good password, but how do we share it?
   echo
   echo "Top secret password: $POSTGRES_PASSWORD"
   echo
 }

 echo "$POSTGRES_PASSWORD" > "$PWFILE" # meant for initdb

 # Optional: Save file to filename specified by POSTGRES_PASSWORD_SAVE
 [ ! -z "$POSTGRES_PASSWORD_SAVE" ] &&
 {
   echo "$POSTGRES_PASSWORD" > "$POSTGRES_PASSWORD_SAVE"
 }

 su-exec $POSTGRES_USER initdb -D "$PGDATA" \
                               --username="$INTERNAL_USER" \
                               --pwfile=$PWFILE || return $?

 rm "$PWFILE"

 hba_setup || return $?

 su-exec $POSTGRES_USER pg_ctl -D "$PGDATA" \
                               -o "-c listen_addresses=''" \
                               -w start || return $?

 # setup extensions if any

 [ -f "/tmp/extensions.txt" ] &&
 {
  extensions=$(cat /tmp/extensions.txt )
  databases="postgres template1"
  for database in $databases
  do
   {
    for extension in $extensions
    do
      echo "CREATE EXTENSION IF NOT EXISTS $extension CASCADE;"  | psql -U "${INTERNAL_USER}" ${database} 2>&1
    done
   }
  done
 }

 # additional setup to be added here
 su-exec $POSTGRES_USER pg_ctl -D "$PGDATA" -m fast -w stop
}

## MAIN ##

[ ! -e "${PGDATA}/PG_VERSION" ] && pg_setup || exit $?

su-exec ${POSTGRES_USER} postgres $*
