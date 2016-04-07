if  [ -d "/home/admin/" ]; then
	H=/home/admin/
else
	H=/home/website/
fi
WORK_DIR=${H}Planet/

osmosis=${H}"src/osmosis/bin/osmosis -q"
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
echo $(date)' updating mapnik DB'
/usr/local/bin/osm2pgsql -U mapnik -s -c -m -d $DBMAPNIKTMP -S ${CONFIG_DIR}pistes.style\
 ${PLANET_DIR}planet_pistes.osm > /dev/null 2>&1
if [ $? -ne 0 ]
then
    echo $(date)' FAILED update TMP mapnik db'
    exit 4
else echo $(date)' update TMP mapnik db succeed '
fi

${TOOLS_DIR}./make_sites.py ${H}
${TOOLS_DIR}./relations_down.py > /dev/null

##########################################
#~ List expired tiles from the 2 databases, the old and the new
##########################################

cd ${TOOLS_DIR}
./list_expired.py ${PLANET_DIR}daily.osc

##########################################
#~ swap the 2 databases, the old and the new
##########################################

monit unmonitor renderd # http must be enabled in /etc/monit/monitrc
/usr/sbin/service renderd stop
## procpid or pid for PG < 9.2
echo "SELECT
    pg_terminate_backend (pg_stat_activity.procpid)
FROM
    pg_stat_activity
WHERE
    pg_stat_activity.datname = 'pistes-mapnik';" | psql -d $DBMAPNIKTMP
#~ echo "SELECT
    #~ pg_terminate_backend (pg_stat_activity.pid)
#~ FROM
    #~ pg_stat_activity
#~ WHERE
    #~ pg_stat_activity.datname = 'pistes-mapnik';" | psql -d $DBMAPNIKTMP
dropdb $DBMAPNIK
createdb -T $DBMAPNIKTMP $DBMAPNIK

cd ${H}mapnik/offset-style/
python build-relations-style.py lists
cd ${H}mapnik/single-overlay/
python build-relations-style.py lists

/usr/sbin/service renderd start
monit monitor renderd


##########################################
## Expire tiles, touch only
##########################################
# to stop expiry:
#~ touch -d "2 years ago" /var/lib/mod_tile/planet-import-complete 
# to start default expiry 
#~ touch /var/lib/mod_tile/planet-import-complete
# expiry from tile list: we never change the planet timestamp, just mark the 
# relevant tiles as expired. Done on 07042016
cd ${TOOLS_DIR}
cat expired_tiles.lst | render_expired --map=single --touch-from=0 --num-threads=1

#~ /etc/init.d/renderd restart

cd ${WORK_DIR}

##########################################

##########################################


#~ TESTSIZE=$(stat -c%s ${PLANET_DIR}planet_pistes.osm)
#~ if [ $TESTSIZE -gt 1000 ]
#~ then echo $(date)' planet_pistes.osm ok, updating XAPI DB'
    #~ #Updating DB for osmosis:
    #~ $osmosis --truncate-pgsql host="localhost" \
    #~ database="pistes-xapi" user="xapi" password="xapi"
    #~ if [ $? -ne 0 ]
    #~ then
        #~ echo $(date)' truncate DB failed'
        #~ exit 5
    #~ fi
    #~ $osmosis --read-xml ${PLANET_DIR}planet_pistes.osm \
    #~ --write-pgsql host="localhost" database="pistes-xapi" user="xapi" password="xapi"
    #~ if [ $? -ne 0 ]
    #~ then
        #~ echo $(date)' Osmosis failed to update DB'
        #~ exit 5
    #~ fi
    
    
    #~ # Copy the total way length and last update.txt infos to the website
#~ 
#~ else 
    #~ echo $(date)' planet_pistes_processed.osm empty'
    #~ exit 5
#~ fi
#~ # backup

${TOOLS_DIR}./pistes-stat2json.sh >${PLANET_DIR}stats.json
cp ${PLANET_DIR}stats.json /var/www/data/stats.json

echo $(date)' Update complete'

${TOOLS_DIR}./06-pgsnapshot.sh


