
#~ createdb pistes-pgsnapshot
#~ psql -d pistes-pgsnapshot -f /usr/share/postgresql/9.1/contrib/postgis-2.0/postgis.sql
#~ psql -d pistes-pgsnapshot -f /usr/share/postgresql/9.1/contrib/postgis-2.0/spatial_ref_sys.sql
#~ echo "CREATE EXTENSION hstore;"  | psql -d pistes-pgsnapshot
#~ echo "CREATE EXTENSION pg_trgm;"  | psql -d pistes-pgsnapshot
#~ psql -d pistes-pgsnapshot -f /home/website/src/osmosis-0.43.1/script/pgsnapshot_schema_0.6.sql
#~ psql -d pistes-pgsnapshot -f /home/website/src/osmosis-0.43.1/script/pgsnapshot_schema_0.6_bbox.sql
#~ psql -d pistes-pgsnapshot -f /home/website/src/osmosis-0.43.1/script/pgsnapshot_schema_0.6_linestring.sql
#~ psql -d pistes-pgsnapshot -f /home/website/src/osmosis-0.43.1/script/pgsnapshot_schema_0.6_action.sql
#~ psql -d pistes-pgsnapshot -f /home/website/Planet/config/pgsnapshot_schema_0.6_relations_geometry.sql
#~ psql -d pistes-pgsnapshot -f /home/website/Planet/config/pgsnapshot_schema_0.6_names.sql
#~ psql -d pistes-pgsnapshot -f /home/website/Planet/config/pgsnapshot_schema_0.6_relations_types.sql

#~ createdb pistes-pgsnapshot-tmp
#~ psql -d pistes-pgsnapshot-tmp -f /usr/share/postgresql/9.1/contrib/postgis-2.0/postgis.sql
#~ psql -d pistes-pgsnapshot-tmp -f /usr/share/postgresql/9.1/contrib/postgis-2.0/spatial_ref_sys.sql
#~ echo "CREATE EXTENSION hstore;"  | psql -d pistes-pgsnapshot-tmp
#~ echo "CREATE EXTENSION pg_trgm;"  | psql -d pistes-pgsnapshot-tmp
#~ psql -d pistes-pgsnapshot-tmp -f /home/website/src/osmosis-0.43.1/script/pgsnapshot_schema_0.6.sql
#~ psql -d pistes-pgsnapshot-tmp -f /home/website/src/osmosis-0.43.1/script/pgsnapshot_schema_0.6_bbox.sql
#~ psql -d pistes-pgsnapshot-tmp -f /home/website/src/osmosis-0.43.1/script/pgsnapshot_schema_0.6_linestring.sql
#~ psql -d pistes-pgsnapshot-tmp -f /home/website/src/osmosis-0.43.1/script/pgsnapshot_schema_0.6_action.sql
#~ psql -d pistes-pgsnapshot-tmp -f /home/website/Planet/config/pgsnapshot_schema_0.6_relations_geometry.sql
#~ psql -d pistes-pgsnapshot-tmp -f /home/website/Planet/config/pgsnapshot_schema_0.6_names.sql
#~ psql -d pistes-pgsnapshot-tmp -f /home/website/Planet/config/pgsnapshot_schema_0.6_relations_types.sql

osmosis="/home/website/src/osmosis-0.43.1/bin/osmosis"
WORK_DIR=/home/website/Planet/
cd ${WORK_DIR}
# This script log
LOGFILE=${WORK_DIR}log/planet_update.log
# Directory where the planet file is stored
PLANET_DIR=${WORK_DIR}data/
TMP_DIR=${WORK_DIR}tmp/
TOOLS_DIR=${WORK_DIR}tools/
CONFIG_DIR=${WORK_DIR}config/

DBTMP=pistes-pgsnapshot-tmp
DB=pistes-pgsnapshot

TESTSIZE=$(stat -c%s ${PLANET_DIR}planet_pistes.osm)
if [ $TESTSIZE -gt 1000 ]
then echo $(date)' planet_pistes.osm ok, updating pgsnapshot DB'
    #Updating DB for osmosis:
    $osmosis --truncate-pgsql host="localhost" \
    database=$DBTMP
    if [ $? -ne 0 ]
    then
        echo $(date)' truncate DB failed'
        exit 5
    fi
    $osmosis --read-xml ${PLANET_DIR}planet_pistes.osm \
    --write-pgsql host="localhost" database=$DBTMP
    if [ $? -ne 0 ]
    then
        echo $(date)' Osmosis failed to update pgsnapshot DB'
        exit 5
    fi
    dropdb $DB
	createdb -T $DBTMP $DB
    
    #~ # Copy the total way length and last update.txt infos to the website
#~ 
else 
    echo $(date)' planet_pistes.osm empty'
    exit 5
fi
