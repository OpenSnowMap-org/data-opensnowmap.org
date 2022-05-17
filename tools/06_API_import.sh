#!/bin/bash

#______________________________________________________________________
# This script is intended to keep a planet.osm.gz file up to date with
# daily diffs. 
# It is not necessary to run the scipt every day.
# It will exit 2 on error, 1 if there is nothing to do, and 0 if update 
# is succesfull.
#______________________________________________________________________
H=/home/admin/

WORK_DIR=${H}Planet/

# This script log
LOGFILE=${WORK_DIR}log/planet_update-osmium.log
# Directory where the planet file is stored
PLANET_DIR=${WORK_DIR}data/
TMP_DIR=${WORK_DIR}tmp/
TOOLS_DIR=${WORK_DIR}tools/
ARCHIVE_DIR=${WORK_DIR}archives/
DOWNLOADS_DIR=${H}downloadable/
CONFIG_DIR=${WORK_DIR}config/
cd ${TOOLS_DIR}
echo '#########################'
echo $(date)' Update API DB'
echo '#########################'
#~ createuser -d osmuser
dropdb pistes_api_osm2pgsql_temp -U osmuser
createdb --encoding=UTF8 --owner=osmuser pistes_api_osm2pgsql_temp -U osmuser
psql pistes_api_osm2pgsql_temp --command='CREATE EXTENSION IF NOT EXISTS postgis;' -U osmuser
psql pistes_api_osm2pgsql_temp --command='CREATE EXTENSION IF NOT EXISTS hstore;' -U osmuser
psql pistes_api_osm2pgsql_temp --command='CREATE EXTENSION IF NOT EXISTS pgrouting;' -U osmuser
psql pistes_api_osm2pgsql_temp --command='CREATE EXTENSION IF NOT EXISTS pg_trgm;' -U osmuser

# Note: tested with version osm2pgsql 1.6.0 (1.6.0-29-gdef97005) git checkout def97005
/home/admin/SRC/osm2pgsql/build/osm2pgsql -U osmuser --create ${PLANET_DIR}planet_pistes-osmium.osm.pbf --database=pistes_api_osm2pgsql_temp --output=flex --style=${CONFIG_DIR}opensnowmap.lua 
#~ --log-level=debug --log-sql-data
cat ${CONFIG_DIR}postprocess_api.sql | psql -U osmuser -d pistes_api_osm2pgsql_temp 
python ${TOOLS_DIR}scripts/postprocess_api.py
cat ${CONFIG_DIR}postprocess_pgrouting.sql | psql -d pistes_api_osm2pgsql_temp -U osmuser

##########################################
#~ swap the 2 databases, the old and the new
##########################################

#~ systemctl stop renderd.service

echo "SELECT
    pg_terminate_backend (pg_stat_activity.pid)
FROM
    pg_stat_activity
WHERE
    pg_stat_activity.datname = 'pistes_api_osm2pgsql';" | psql -d pistes_api_osm2pgsql_temp -U osmuser

echo $(date)' replace mapnik DB'
dropdb pistes_api_osm2pgsql -U osmuser 
createdb -U osmuser -T pistes_api_osm2pgsql_temp pistes_api_osm2pgsql

echo '#########################'
echo $(date)' API DB Updated'
echo '#########################'

cat /home/admin/Planet/log/daily-osmium.log | msmtp admin@opensnowmap.org
