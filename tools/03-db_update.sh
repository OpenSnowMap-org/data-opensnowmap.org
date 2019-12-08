
H=/home/admin/

WORK_DIR=${H}Planet/
cd ${WORK_DIR}

# This script log
LOGFILE=${WORK_DIR}log/planet_update.log
# Directory where the planet file is stored
PLANET_DIR=${WORK_DIR}data/
TMP_DIR=${WORK_DIR}tmp/
TOOLS_DIR=${WORK_DIR}tools/
CONFIG_DIR=${WORK_DIR}config/
ARCHIVE_DIR=${WORK_DIR}archives/


DBMAPNIK=pistes-mapnik
DBMAPNIKTMP=pistes-mapnik-tmp
DBMAPNIKAWEEKAGO=pistes-mapnik-a-week-ago

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

${TOOLS_DIR}scripts/./make_sites.py ${WORK_DIR}
${TOOLS_DIR}scripts/./relations_down.py

##########################################
#Create new nodes files weekly.tsv, daily.tsv for openlayers change view
##########################################

# Populate mapnik db with a week old extract for changes
lastweek=$(date --date="1 week ago" +%Y-%m-%d)
lastweek_file=${ARCHIVE_DIR}planet_pistes-$lastweek.osm.gz
    if [ -f $lastweek_file ];
    then
        gunzip -c $lastweek_file > ${PLANET_DIR}planet_pistes_last_week.osm
        echo $(date)' weekly.osc done'
    else
        echo $(date)' no lastweek file found' $lastweek_file
    fi
    
echo $(date)' updating weekly TMP mapnik DB'
/usr/bin/osm2pgsql -U mapnik -E 3857 -s -c -m -d $DBMAPNIKAWEEKAGO -S ${CONFIG_DIR}pistes.style\
 ${PLANET_DIR}planet_pistes_last_week.osm > /dev/null 2>&1
if [ $? -ne 0 ]
then
    echo $(date)' FAILED update weekly TMP mapnik db'
    exit 4
else echo $(date)' update weekly TMP mapnik db succeed '
fi

${TOOLS_DIR}scripts/./list_changes_advanced_complete.py ${PLANET_DIR}daily.osc $DBMAPNIKTMP $DBMAPNIK ${PLANET_DIR} daily
${TOOLS_DIR}scripts/./list_changes_advanced_complete.py ${PLANET_DIR}weekly.osc $DBMAPNIKTMP $DBMAPNIKAWEEKAGO ${PLANET_DIR} weekly

cp ${PLANET_DIR}*.csv  /var/www/data/

##########################################
#~ List expired tiles from the 2 databases, the old and the new
##########################################

cd ${TOOLS_DIR}
if [ -f ${PLANET_DIR}dailyok ];
then
    ${TOOLS_DIR}script/./list_expired.py ${PLANET_DIR}daily.osc $DBMAPNIKTMP $DBMAPNIK
else 
    echo '#######################################'
    echo '            EXPIRE MANUALLY !'
    echo '#######################################'
fi


##########################################
#~ swap the 2 databases, the old and the new
##########################################

#~ systemctl stop renderd.service

echo "SELECT
    pg_terminate_backend (pg_stat_activity.pid)
FROM
    pg_stat_activity
WHERE
    pg_stat_activity.datname = 'pistes-mapnik';" | psql -d $DBMAPNIKTMP -U mapnik

echo $(date)' replace mapnik DB'
dropdb -U mapnik $DBMAPNIK
createdb -U mapnik -T $DBMAPNIKTMP $DBMAPNIK


echo $(date)' update relations style for osm2pgsql style'
cd ${H}mapnik/pistes-only-clean2017/
python build-relations-style.py ../offset_lists
xmllint -noent ${H}mapnik/pistes-only-clean2017/map.xml > ${H}mapnik/pistes-only-clean2017/full.xml

cd ${H}mapnik/pistes-relief-clean2017/
python build-relations-style.py ../offset_lists
xmllint -noent ${H}mapnik/pistes-relief-clean2017/map.xml > ${H}mapnik/pistes-relief-clean2017/full.xml

echo $(date)' restart renderd'
systemctl restart renderd.service 

##########################################
## Compute daily pistes stats
##########################################

${TOOLS_DIR}scripts/./pistes-stat2json.sh >${PLANET_DIR}stats.json
cp ${PLANET_DIR}stats.json /var/www/data/stats.json

echo $(date)' Update complete'

${TOOLS_DIR}./04-pistes_imposm_reload.sh


