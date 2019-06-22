#!/bin/sh

## ENVIRONMENT ##

# this should be automatically detected from the build (not environment?)
export POSTGRES_USER=pg

## FUNCTIONS ##

generate_password()
{
 pwgen -ysc -r "\`" 16 1
}

pg_setup()
{
 local INTERNAL_USER="postgres"
 local PWFILE="pw.${RANDOM}${RANDOM}"

 chmod 750 ${PGDATA}

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
                               --pwfile=$pwfile || return $?

 su-exec $POSTGRES_USER pg_ctl -D "$PGDATA" \
                               -o "-c listen_addresses=''" \
                               -w start || return $?

 # WIP: add extensions
 ls -lt ${PGDATA}/postgresql.conf

 # additional setup to be added here
 su-exec $POSTGRES_USER pg_ctl -D "$PGDATA" -m fast -w stop
}

## MAIN ##

[ ! -e "${PGDATA}/PG_VERSION" ] && pg_setup || exit $?

su-exec pg postgres $*
