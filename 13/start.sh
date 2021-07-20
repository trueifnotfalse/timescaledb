#!/bin/bash

function start_postgres {
    eval "gosu postgres /usr/lib/postgresql/$PG_VERSION/bin/postgres -D $PGDATA -c config_file=/etc/postgresql/$PG_VERSION/main/postgresql.conf"
}

function load_init_sql {
    eval "gosu postgres /usr/lib/postgresql/$PG_VERSION/bin/pg_ctl -D $PGDATA -o \"-c listen_addresses='localhost'\" -w start"

    for f in /init_sql/*; do
        case "$f" in
            *.sql)  echo "$0: running $f"; /usr/lib/postgresql/$PG_VERSION/bin/psql postgres postgres -f "$f"; echo ;;
        esac
    done

    eval "gosu postgres /usr/lib/postgresql/$PG_VERSION/bin/pg_ctl -D $PGDATA -m fast -w stop"
}

mkdir -p "$PGDATA"
chown -R postgres "$PGDATA" 2>/dev/null || :
chmod 700 "$PGDATA" 2>/dev/null || :

if [ ! -s "$PGDATA/PG_VERSION" ]; then

    if [ "$POSTGRES_BACKUP_HOST" ]; then

        if [ -f "$PGDATA/recovery.conf" ]; then
            sudo rm "$PGDATA/recovery.conf"

        fi

        export PGPASSWORD="$POSTGRES_BACKUP_PASSWORD"
        eval "gosu postgres  /usr/lib/postgresql/$PG_VERSION/bin/pg_basebackup -R -X $POSTGRES_BACKUP_WAL_METHOD -c $POSTGRES_BACKUP_CHECKPOINT -h $POSTGRES_BACKUP_HOST -U postgres -D $PGDATA"

        if [ "$POSTGRES_BACKUP_DELAY" ]; then
            echo "recovery_min_apply_delay = '$POSTGRES_BACKUP_DELAY'" >> "$PGDATA/recovery.conf"
        fi

    else

        POSTGRES_INITDB_ARGS="-D $PGDATA"
        if [ "$POSTGRES_INITDB_WALDIR" ]; then
            export POSTGRES_INITDB_ARGS="$POSTGRES_INITDB_ARGS --waldir $POSTGRES_INITDB_WALDIR"
        fi

        if [ "$POSTGRES_PASSWORD" ]; then
            pass="$POSTGRES_PASSWORD"
        else
            pass="postgres"
        fi

        echo "$pass" > /tmp/passwd
        eval "gosu postgres /usr/lib/postgresql/$PG_VERSION/bin/initdb --pwfile=/tmp/passwd $POSTGRES_INITDB_ARGS"
        rm -rf /tmp/passwd

        if [ "$(ls -A /init_sql/)" ]; then
            load_init_sql
        fi
    fi
fi

start_postgres
