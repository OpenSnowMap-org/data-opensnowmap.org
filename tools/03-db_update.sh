osmosis="/home/admin/src/osmosis/bin/osmosis -q"
WORK_DIR=/home/admin/Planet/
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
    echo $(date)' FAILED update mapnik db'
    exit 4
else echo $(date)' update mapnik db succeed '
fi

${TOOLS_DIR}./make_sites.py
${TOOLS_DIR}./relations_down.py > /dev/null

service renderd stop
/etc/init.d/renderd stop
dropdb $DBMAPNIK
createdb -T $DBMAPNIKTMP $DBMAPNIK
/etc/init.d/renderd start
service renderd start

touch /var/lib/mod_tile/planet-import-complete

cd /home/admin/mapnik/offset-style/
python build-relations-style.py lists
#~ /etc/init.d/renderd restart
cd ${WORK_DIR}

##########################################

##########################################


TESTSIZE=$(stat -c%s ${PLANET_DIR}planet_pistes.osm)
if [ $TESTSIZE -gt 1000 ]
then echo $(date)' planet_pistes.osm ok, updating XAPI DB'
    #Updating DB for osmosis:
    $osmosis --truncate-pgsql host="localhost" \
    database="pistes-xapi" user="xapi" password="xapi"
    if [ $? -ne 0 ]
    then
        echo $(date)' truncate DB failed'
        exit 5
    fi
    $osmosis --read-xml ${PLANET_DIR}planet_pistes.osm \
    --write-pgsql host="localhost" database="pistes-xapi" user="xapi" password="xapi"
    if [ $? -ne 0 ]
    then
        echo $(date)' Osmosis failed to update DB'
        exit 5
    fi
    
    
    #~ # Copy the total way length and last update.txt infos to the website
#~ 
else 
    echo $(date)' planet_pistes_processed.osm empty'
    exit 5
fi
#~ # backup

${TOOLS_DIR}./pistes-stat2json.sh >${PLANET_DIR}stats.json
cp ${PLANET_DIR}stats.json /var/www/data/stats.json

echo $(date)' Update complete'

${TOOLS_DIR}./06-pgsnapshot.sh
${TOOLS_DIR}./04-osmand_export.sh

