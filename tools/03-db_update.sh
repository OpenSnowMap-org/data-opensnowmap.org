
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
ARCHIVE_DIR=${WORK_DIR}archives/


DBMAPNIK=pistes-mapnik
DBMAPNIKTMP=pistes-mapnik-tmp
DBMAPNIKAWEEKAGO=pistes-mapnik-a-week-ago

psql -U admin -lqt | cut -d \| -f 1 | grep -qw $DBMAPNIKTMP;
if [ $? = 0 ]; then
    echo $(date)' Database $DBMAPNIKTMP found'
else
    createdb -U admin -D data_raid -E UTF8 -O mapnik $DBMAPNIKTMP
    psql -d $DBMAPNIKTMP -U mapnik -c "CREATE EXTENSION postgis;"
    psql -d $DBMAPNIKTMP -U mapnik -c "CREATE EXTENSION hstore;" # only required for hstore support
    echo "ALTER USER mapnik WITH PASSWORD 'mapnik';" |psql -U mapnik -d $DBMAPNIKTMP
fi

psql -U admin -lqt | cut -d \| -f 1 | grep -qw $DBMAPNIKAWEEKAGO;
if [ $? = 0 ]; then
    echo $(date)' Database $DBMAPNIKAWEEKAGO found'
else
    createdb -U admin -D data_raid -E UTF8 -O mapnik $DBMAPNIKAWEEKAGO
    psql -d $DBMAPNIKAWEEKAGO -U mapnik -c "CREATE EXTENSION postgis;"
    psql -d $DBMAPNIKAWEEKAGO -U mapnik -c "CREATE EXTENSION hstore;" # only required for hstore support
    echo "ALTER USER mapnik WITH PASSWORD 'mapnik';" |psql -U mapnik -d $DBMAPNIKAWEEKAGO
fi

#~ psql -U admin -lqt | cut -d \| -f 1 | grep -qw pistes_imposm_tmp
#~ if [ $? = 0 ]; then
    #~ echo $(date)' Databases pistes_imposm_tmp found'
#~ else
    #~ dropdb -U admin --if-exists pistes_imposm_tmp
    #~ createdb -U admin -E UTF8 -O imposm pistes_imposm_tmp -D data_raid
    #~ psql -U admin -d pistes_imposm_tmp -c "CREATE EXTENSION postgis;"
    #~ psql -U admin -d pistes_imposm_tmp -c "CREATE EXTENSION hstore;" # only required for hstore support
    #~ echo "ALTER USER imposm WITH PASSWORD 'imposm';" |psql -U imposm -d pistes_imposm_tmp
#~ fi

# Populate mapnik db
echo $(date)' updating TMP mapnik DB'
/usr/bin/osm2pgsql -U mapnik -E 3857 -s -c -m -d $DBMAPNIKTMP -S ${CONFIG_DIR}pistes.style\
 ${PLANET_DIR}planet_pistes-osmium.osm > /dev/null 2>&1
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


echo $(date)' updating daily changes'
lastday=$(date --date="1 day ago" +%Y-%m-%d)
lastday_file=${ARCHIVE_DIR}planet_pistes-osmium-$lastday.osm.gz
    if [ -f $lastday_file ];
    then
        echo $(date)' computing changes '
        ${TOOLS_DIR}scripts/./list_changes_advanced_complete.py ${PLANET_DIR}daily-osmium.osc $DBMAPNIKTMP $DBMAPNIK ${PLANET_DIR} daily
        
    else
        echo $(date)' no yesterday file found' $lastday_file
    fi
    
echo $(date)' updating weekly changes'

# Populate mapnik db with a week old extract for changes
lastweek=$(date --date="1 week ago" +%Y-%m-%d)
lastweek_file=${ARCHIVE_DIR}planet_pistes-osmium-$lastweek.osm.gz
    if [ -f $lastweek_file ];
    then
        gunzip -c $lastweek_file > ${PLANET_DIR}planet_pistes-osmium_last_week.osm
        echo $(date)' weekly.osc done'
        
        /usr/bin/osm2pgsql -U mapnik -E 3857 -s -c -m -d $DBMAPNIKAWEEKAGO -S ${CONFIG_DIR}pistes.style\
         ${PLANET_DIR}planet_pistes-osmium_last_week.osm 
        if [ $? -ne 0 ]
        then
            echo $(date)' FAILED update weekly TMP mapnik db'
        else 
            echo $(date)' update weekly TMP mapnik db succeed '
            echo $(date)' computing changes '
            ${TOOLS_DIR}scripts/./list_changes_advanced_complete.py ${PLANET_DIR}weekly-osmium.osc $DBMAPNIKTMP $DBMAPNIKAWEEKAGO ${PLANET_DIR} weekly
        fi
    else
        echo $(date)' no lastweek file found' $lastweek_file
    fi
    
echo $(date)' publishing changes'
cp ${PLANET_DIR}*.csv  /var/www/data/

##########################################
#~ List expired tiles from the 2 databases, the old and the new
##########################################

cd ${TOOLS_DIR}
if [ -f ${PLANET_DIR}daily-osmium.osc ];
then
    ${TOOLS_DIR}scripts/./list_expired.py ${PLANET_DIR}daily-osmium.osc $DBMAPNIKTMP $DBMAPNIK
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
#~ cd ${H}mapnik/pistes-only-clean2017/
#~ python build-relations-style.py ../offset_lists
#~ xmllint -noent ${H}mapnik/pistes-only-clean2017/map.xml > ${H}mapnik/pistes-only-clean2017/full.xml

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


