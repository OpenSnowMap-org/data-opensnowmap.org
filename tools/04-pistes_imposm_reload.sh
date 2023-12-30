H=/home/admin/
WORK_DIR=${H}Planet/

cd ${WORK_DIR}
# This script log
LOGFILE=${WORK_DIR}log/planet_update-osmium.log
# Directory where the planet file is stored
PLANET_DIR=${WORK_DIR}data/
TMP_DIR=${WORK_DIR}tmp/
TOOLS_DIR=${WORK_DIR}tools/
CONFIG_DIR=${WORK_DIR}config/


# Populate imposm db
    dropdb -U admin --if-exists pistes_imposm_tmp
    createdb -U admin -E UTF8 -O imposm pistes_imposm_tmp -D data_raid
    psql -U admin -d pistes_imposm_tmp -c "CREATE EXTENSION postgis;"
    psql -U admin -d pistes_imposm_tmp -c "CREATE EXTENSION hstore;" # only required for hstore support
    echo "ALTER USER imposm WITH PASSWORD 'imposm';" |psql -U imposm -d pistes_imposm_tmp

readonly PG_CONNECT="postgis://imposm:imposm@localhost/pistes_imposm_tmp"

osmconvert ${PLANET_DIR}planet_pistes-osmium.osm -o=${PLANET_DIR}planet_pistes-osmium.osm.pbf

readonly inputpbf=${PLANET_DIR}planet_pistes-osmium.osm.pbf
#~ readonly inputpbf=/nvme-data/data/europe-latest.osm.pbf
readonly mappingfile=${CONFIG_DIR}pistes.yml

echo "$(date) - importing: $inputpbf "
mkdir -p /home/admin/imposm_cache_pistes

imposm import \
    -quiet \
    -mapping $mappingfile \
    -read $inputpbf \
    -write \
    -optimize \
    -overwritecache \
    -diff -cachedir "/home/admin/imposm_cache_pistes" -diffdir "/home/admin/imposm_cache_pistes" \
    -deployproduction \
    -connection $PG_CONNECT

/home/yves/OPENSNOWMAP/Planet.git/tools/scripts/./build_render_colors.py
cat /home/yves/OPENSNOWMAP/Planet.git/config/postprocess_nordic_routes.sql |psql --echo-all -U imposm -d pistes_imposm_tmp
cat /home/yves/OPENSNOWMAP/Planet.git/config/postprocess_resorts.sql |psql --echo-all -U imposm -d pistes_imposm_tmp

echo "$(date) - Switch DBs"
echo "SELECT pg_terminate_backend(pg_stat_activity.pid)
FROM pg_stat_activity
WHERE pg_stat_activity.datname = 'pistes_imposm' 
  AND pid <> pg_backend_pid();" | psql -d pistes_imposm_tmp -U admin
dropdb --if-exists -U admin pistes_imposm
createdb -U admin -T pistes_imposm_tmp pistes_imposm
#~ exit
systemctl restart renderd.service 

echo $(date)' expire tiles'

##########################################
## Expire tiles, touch only
##########################################
# to stop expiry:
#~ touch -d "2 years ago" /var/lib/mod_tile/planet-import-complete 
# to start default expiry 
#~ touch /var/lib/mod_tile/planet-import-complete
# expiry from tile list: we never change the planet timestamp, just mark the 
# relevant tiles as expired. Done on 07042016
# 

cat ${PLANET_DIR}expired_tiles.lst | grep -v "-" |/usr/local/bin/render_expired --tile-dir /var/lib/mod_tile/ --map=pistes-relief --num-threads=1 --touch-from=0 
echo $(date)' expire tiles'
cat ${PLANET_DIR}expired_tiles.lst | grep -v "-" | /usr/local/bin/render_expired --tile-dir /var/lib/mod_tile/ --map=pistes --num-threads=1 --touch-from=0 
echo $(date)' expire tiles'
cat ${PLANET_DIR}expired_tiles.lst | grep -v "-" | /usr/local/bin/render_expired --tile-dir /var/lib/mod_tile/ --map=pistes-high-dpi --num-threads=1 --touch-from=0 
echo $(date)' expire tiles'
cat ${PLANET_DIR}expired_tiles.lst | grep -v "-" | /usr/local/bin/render_expired --tile-dir /var/lib/mod_tile/ --map=base_snow_map --num-threads=1 --touch-from=0 
echo $(date)' expire tiles'
cat ${PLANET_DIR}expired_tiles.lst | grep -v "-" | /usr/local/bin/render_expired --tile-dir /var/lib/mod_tile/ --map=base_snow_map_high_dpi --num-threads=1 --touch-from=0 


cd ${WORK_DIR}

echo $(date)' Update complete'
cat /home/admin/Planet/log/daily.log | msmtp admin@opensnowmap.org

cd ${TOOLS_DIR}
./06_API_import.sh
