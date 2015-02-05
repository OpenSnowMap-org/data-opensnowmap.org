#~ sudo su postgres
#~ createuser -s mapnik
#~ createdb ww-mapnik -U mapnik
#~ psql -d ww-mapnik -U mapnik  -f /usr/share/postgresql/9.3/contrib/postgis-2.1/postgis.sql
#~ psql -d ww-mapnik -U mapnik -f /usr/share/postgresql/9.3/contrib/postgis-2.1/spatial_ref_sys.sql
#~ createdb ww-mapnik-tmp -U mapnik
#~ psql -d ww-mapnik-tmp -U mapnik  -f /usr/share/postgresql/9.3/contrib/postgis-2.1/postgis.sql
#~ psql -d ww-mapnik-tmp -U mapnik -f /usr/share/postgresql/9.3/contrib/postgis-2.1/spatial_ref_sys.sql

if  [ -d "/home/admin/" ]; then
	H=/home/admin/
else
	H=/home/website/
fi
WORK_DIR=${H}Planet/
osmosis="$H/src/osmosis/bin/osmosis -q"

# This script log
LOGFILE=${WORK_DIR}log/planet_update.log
# Directory where the planet file is stored
PLANET_DIR=${WORK_DIR}data/
TMP_DIR=${WORK_DIR}tmp/
TOOLS_DIR=${WORK_DIR}tools/
ARCHIVE_DIR=${WORK_DIR}archives/
DOWNLOADS_DIR=${H}downloadable/

CONFIG_DIR=${WORK_DIR}config/
cd ${TOOLS_DIR}

#~ createdb -T pistes-mapnik ww-mapnik 

DBMAPNIKTMP=ww-mapnik-tmp
DBMAPNIK=ww-mapnik

# Populate mapnik db
echo $(date)' updating mapnik DB'
/usr/bin/osm2pgsql -U mapnik -s -c -m -d $DBMAPNIKTMP -S ${CONFIG_DIR}watersports.style\
 ${PLANET_DIR}planet_ww.osm #> /dev/null 2>&1
if [ $? -ne 0 ]
then
    echo $(date)' FAILED update TMP mapnik db'
    exit 4
else echo $(date)' update TMP mapnik db succeed '
fi
echo $(date)' unmonitor renderd'
monit unmonitor renderd # http must be enabled in /etc/monit/monitrc
echo $(date)' stop renderd'
/usr/sbin/service renderd stop
echo "SELECT
    pg_terminate_backend (pg_stat_activity.pid)
FROM
    pg_stat_activity
WHERE
    pg_stat_activity.datname = 'pistes-mapnik';" | psql -d $DBMAPNIKTMP
    
dropdb $DBMAPNIK
createdb -T $DBMAPNIKTMP $DBMAPNIK

/usr/sbin/service renderd start
echo $(date)' start renderd'
monit monitor renderd
echo $(date)' remonitor renderd'
