FROM debian:10-slim

ENV DEBIAN_FRONTEND=noninteractive

ENV LANG en_US.utf8

ENV PG_VERSION 13
ENV POSTGIS_VERSION 3
ENV TIME_SCALE_DB_VERSION 2.3.1
ENV PGDATA /var/lib/postgresql/$PG_VERSION/main
ENV POSTGRES_BACKUP_CHECKPOINT fast
ENV POSTGRES_BACKUP_WAL_METHOD stream

RUN apt-get update && \
    apt-get install -y wget gosu ca-certificates gnupg2 locales clang clang-format cmake make git libssl-dev libkrb5-dev && \
    localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8 && \
    echo "deb http://apt.postgresql.org/pub/repos/apt/ buster-pgdg main" >> /etc/apt/sources.list.d/pgdg.list && \
    wget --no-check-certificate --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - && \
    apt-get update && \
    apt-get install -y --no-install-recommends postgresql-$PG_VERSION postgresql-$PG_VERSION-postgis-$POSTGIS_VERSION postgresql-server-dev-$PG_VERSION && \
    rm -rf $PGDATA && \
    sed -ri "s!^#?(listen_addresses)\s*=\s*\S+.*!\1 = '*'!" /etc/postgresql/$PG_VERSION/main/postgresql.conf && \
    echo "host all all all md5" >> "/etc/postgresql/$PG_VERSION/main/pg_hba.conf" && \
    sed -i "s/postgres.\+peer/all   trust/g" /etc/postgresql/$PG_VERSION/main/pg_hba.conf && \
    rm -rf /var/run/postgresql/* && \
    mkdir /var/run/postgresql/$PG_VERSION-main.pg_stat_tmp && \
    chown -R postgres:postgres /var/run/postgresql && \
    chmod 2777 /var/run/postgresql && \
    rm -rf /var/lib/postgresql/$PG_VERSION/main/* && \
    mkdir -p "$PGDATA" && \
    chown -R postgres:postgres "$PGDATA" && \
    chmod 777 "$PGDATA" && \
    git clone --branch $TIME_SCALE_DB_VERSION https://github.com/timescale/timescaledb.git /tmp/timescaledb && \
    cd /tmp/timescaledb && \
    ./bootstrap -DUSE_OPENSSL=0 -DREGRESS_CHECKS=OFF -DGENERATE_DOWNGRADE_SCRIPT=ON -DWARNINGS_AS_ERRORS=OFF && \
    cd build && \
    make && \
    make install && \
    echo "shared_preload_libraries = 'timescaledb'" >> /etc/postgresql/$PG_VERSION/main/postgresql.conf && \
    rm -rf /tmp/timescaledb && \
    apt-get remove -y wget exim4-base exim4-config mailutils gnupg2 gpg ca-certificates clang clang-format cmake make git libkrb5-dev libssl-dev && \
    apt-get auto-remove -y

VOLUME /var/lib/postgresql/$PG_VERSION/main

EXPOSE 5432

COPY start.sh /usr/bin/

CMD ["start.sh"]
