if  [ -d "/home/admin/" ]; then
	H=/home/admin/
else
	H=/home/website/
fi

WORK_DIR=${H}Planet/

#osmosis=${H}"src/osmosis/bin/osmosis -q"
osmosis="osmosis -q"
cd ${WORK_DIR}
# This script log
LOGFILE=${WORK_DIR}log/planet_update.log
# Directory where the planet file is stored
PLANET_DIR=${WORK_DIR}data/
TMP_DIR=${WORK_DIR}tmp/
TOOLS_DIR=${WORK_DIR}tools/
CONFIG_DIR=${WORK_DIR}config/

DBMAPNIKTMP=pistes-mapnik-tmp
DBMAPNIK=pistes-mapnik

# Populate mapnik db
echo $(date)' updating TMP mapnik DB'
/usr/bin/osm2pgsql -U mapnik -E 3857 -s -c -m -d $DBMAPNIKTMP -S ${CONFIG_DIR}pistes.style\
 ${PLANET_DIR}planet_pistes.osm > /dev/null 2>&1
if [ $? -ne 0 ]
then
    echo $(date)' FAILED update TMP mapnik db'
    exit 4
else echo $(date)' update TMP mapnik db succeed '
fi

${TOOLS_DIR}./make_sites.py ${WORK_DIR}
${TOOLS_DIR}./relations_down.py



##########################################
#~ List expired tiles from the 2 databases, the old and the new
##########################################

cd ${TOOLS_DIR}
if [ -f ${PLANET_DIR}dailyok ];
then
    ./list_expired.py ${PLANET_DIR}daily.osc $DBMAPNIKTMP $DBMAPNIK
else 
    echo '#######################################'
    echo '            EXPIRE MANUALLY !'
    echo '#######################################'
fi


##########################################
#~ swap the 2 databases, the old and the new
##########################################

#~ monit unmonitor renderd # http must be enabled in /etc/monit/monitrc
systemctl stop renderd.service
#~ ## procpid or pid for PG < 9.2
echo "SELECT
    pg_terminate_backend (pg_stat_activity.pid)
FROM
    pg_stat_activity
WHERE
    pg_stat_activity.datname = 'pistes-mapnik';" | psql -d $DBMAPNIKTMP -U mapnik

echo $(date)' replace mapnik DB'
dropdb -U mapnik $DBMAPNIK
createdb -U mapnik -T $DBMAPNIKTMP $DBMAPNIK


echo $(date)' update relations style'
cd ${H}mapnik/pistes-only-clean2017/
python build-relations-style.py ../offset_lists
xmllint -noent ${H}mapnik/pistes-only-clean2017/map.xml > ${H}mapnik/pistes-only-clean2017/full.xml
cd ${H}mapnik/pistes-relief-clean2017/
python build-relations-style.py ../offset_lists
xmllint -noent ${H}mapnik/pistes-relief-clean2017/map.xml > ${H}mapnik/pistes-relief-clean2017/full.xml

echo $(date)' restart renderd'
systemctl start renderd.service
#~ monit monitor renderd

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
cd ${TOOLS_DIR}
if [ -f ${PLANET_DIR}dailyok ];
then
    cat expired_tiles.lst | /usr/local/bin/render_expired --map=pistes-relief --num-threads=1 --touch-from=0 
    cat expired_tiles.lst | /usr/local/bin/render_expired --map=pistes --num-threads=1 --touch-from=0 
    cat expired_tiles.lst | /usr/local/bin/render_expired --map=pistes-high-dpi --num-threads=1 --touch-from=0 
    cat expired_tiles.lst | /usr/local/bin/render_expired --map=base_snow_map --num-threads=1 --touch-from=0 
    cat expired_tiles.lst | /usr/local/bin/render_expired --map=base_snow_map_high_dpi --num-threads=1 --touch-from=0 
fi


cd ${WORK_DIR}

##########################################

##########################################

${TOOLS_DIR}./pistes-stat2json.sh >${PLANET_DIR}stats.json
cp ${PLANET_DIR}stats.json /var/www/data/stats.json

echo $(date)' Update complete'

${TOOLS_DIR}./06-pgsnapshot.sh


