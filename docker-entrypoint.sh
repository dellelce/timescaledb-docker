#!/bin/sh

## ENVIRONMENT ##

export POSTGRES_USER=pg # this should be automatically detected

## FUNCTIONS ##

hello()
{
 set
 echo
 echo

 #Temp Stuff
 find /app/pg -name '*.sample'
}

generate_password()
{
 pwgen -ysc -r "\`" 16 1
}

pg_setup()
{
 local internal_user="postgres"
 local pwfile="pw.${RANDOM}${RANDOM}"
 local extensions="/tmp/extensions.txt"

 chmod 750 ${PGDATA}

 [ -z "$POSTGRES_PASSWORD" ] &&
 {
   export POSTGRES_PASSWORD=$(generate_password)
   # we now have a good password, but how do we share it?
   echo
   echo "Top secret password: ${POSTGRES_PASSWORD}" # THIS IS TEMPORARY!
   echo
 }

 echo "${POSTGRES_PASSWORD}" > "$pwfile" # meant for initdb

 # Optional: Save file to filename specified by POSTGRES_PASSWORD_SAVE
 [ ! -z "$POSTGRES_PASSWORD_SAVE" ] &&
 {
   echo "$POSTGRES_PASSWORD" > "$POSTGRES_PASSWORD_SAVE"
 }

 su-exec pg initdb -D "$PGDATA" --username="$POSTGRES_USER" --pwfile=$pwfile || return $?
 su-exec pg pg_ctl -D "$PGDATA" \
                        -o "-c listen_addresses=''" \
                        -w start

 # WIP: add extensions
 ls -lt ${PGDATA}/postgresql.conf
 # additional setup to be added here
 su-exec pg pg_ctl -D "$PGDATA" -m fast -w stop
}

## MAIN ##

hello

[ ! -e "${PGDATA}/PG_VERSION" ] && pg_setup || exit $?

su-exec pg postgres $*
