
#~ createdb pistes-pgsnapshot
#~ psql -d pistes-pgsnapshot -f /usr/share/postgresql/9.6/contrib/postgis-2.3/postgis.sql
#~ psql -d pistes-pgsnapshot -f /usr/share/postgresql/9.6/contrib/postgis-2.3/spatial_ref_sys.sql
#~ echo "CREATE EXTENSION hstore;"  | psql -d pistes-pgsnapshot
#~ echo "CREATE EXTENSION pg_trgm;"  | psql -d pistes-pgsnapshot
#~ psql -d pistes-pgsnapshot -f /home/admin/src/osmosis/script/pgsnapshot_schema_0.6.sql
#~ psql -d pistes-pgsnapshot -f /home/admin/src/osmosis/script/pgsnapshot_schema_0.6_bbox.sql
#~ psql -d pistes-pgsnapshot -f /home/admin/src/osmosis/script/pgsnapshot_schema_0.6_linestring.sql
#~ psql -d pistes-pgsnapshot -f /home/admin/src/osmosis/script/pgsnapshot_schema_0.6_action.sql
#~ psql -d pistes-pgsnapshot -f /home/admin/Planet/config/pgsnapshot_schema_0.6_relations_geometry.sql
#~ psql -d pistes-pgsnapshot -f /home/admin/Planet/config/pgsnapshot_schema_0.6_names.sql
#~ psql -d pistes-pgsnapshot -f /home/admin/Planet/config/pgsnapshot_schema_0.6_relations_types.sql

#~ createdb pistes-pgsnapshot-tmp
#~ psql -d pistes-pgsnapshot-tmp -f /usr/share/postgresql/9.6/contrib/postgis-2.3/postgis.sql
#~ psql -d pistes-pgsnapshot-tmp -f /usr/share/postgresql/9.6/contrib/postgis-2.3/spatial_ref_sys.sql
#~ echo "CREATE EXTENSION hstore;"  | psql -d pistes-pgsnapshot-tmp
#~ echo "CREATE EXTENSION pg_trgm;"  | psql -d pistes-pgsnapshot-tmp
#~ psql -d pistes-pgsnapshot-tmp -f /home/admin/src/osmosis/script/pgsnapshot_schema_0.6.sql
#~ psql -d pistes-pgsnapshot-tmp -f /home/admin/src/osmosis/script/pgsnapshot_schema_0.6_bbox.sql
#~ psql -d pistes-pgsnapshot-tmp -f /home/admin/src/osmosis/script/pgsnapshot_schema_0.6_linestring.sql
#~ psql -d pistes-pgsnapshot-tmp -f /home/admin/src/osmosis/script/pgsnapshot_schema_0.6_action.sql
#~ psql -d pistes-pgsnapshot-tmp -f /home/admin/Planet/config/pgsnapshot_schema_0.6_relations_geometry.sql
#~ psql -d pistes-pgsnapshot-tmp -f /home/admin/Planet/config/pgsnapshot_schema_0.6_names.sql
#~ psql -d pistes-pgsnapshot-tmp -f /home/admin/Planet/config/pgsnapshot_schema_0.6_relations_types.sql

#~ dropdb pistes-pgsnapshot-tmp
#~ createdb pistes-pgsnapshot-tmp
#~ psql -d pistes-pgsnapshot-tmp -f /usr/share/postgresql/9.1/contrib/postgis-2.0/postgis.sql
#~ psql -d pistes-pgsnapshot-tmp -f /usr/share/postgresql/9.1/contrib/postgis-2.0/spatial_ref_sys.sql
#~ echo "CREATE EXTENSION hstore;"  | psql -d pistes-pgsnapshot-tmp
#~ echo "CREATE EXTENSION pg_trgm;"  | psql -d pistes-pgsnapshot-tmp
#~ psql -d pistes-pgsnapshot-tmp -f /home/admin/src/osmosis/script/pgsnapshot_schema_0.6.sql
#~ psql -d pistes-pgsnapshot-tmp -f /home/admin/src/osmosis/script/pgsnapshot_schema_0.6_bbox.sql
#~ psql -d pistes-pgsnapshot-tmp -f /home/admin/src/osmosis/script/pgsnapshot_schema_0.6_linestring.sql
#~ psql -d pistes-pgsnapshot-tmp -f /home/admin/src/osmosis/script/pgsnapshot_schema_0.6_action.sql
## 94 s import
##$osmosis --rxc "test.osc" --wpc database="pistes-pgsnapshot-tmp";
##2 s
#~ psql -d pistes-pgsnapshot-tmp -f /home/admin/Planet/config/pgsnapshot_schema_0.6_relations_geometry.sql
#~ psql -d pistes-pgsnapshot-tmp -f /home/admin/Planet/config/pgsnapshot_schema_0.6_names.sql
#~ psql -d pistes-pgsnapshot-tmp -f /home/admin/Planet/config/pgsnapshot_schema_0.6_relations_types.sql
## 200s import
#~ psql -lqt | cut -d \| -f 1 | grep -qw pistes-pgsnapshot-tmp
#~ if [ $? = 0 ]; then
    #~ echo $(date)' Database pistes-pgsnapshot-tmp found'
#~ else
    #~ createuser -U admin -s xapi
    dropdb -U admin pistes-pgsnapshot-tmp
    createdb -U admin -D data_raid -E UTF8 -O xapi pistes-pgsnapshot-tmp
    psql -U xapi -d pistes-pgsnapshot-tmp -c "CREATE EXTENSION postgis;"
    psql -U xapi -d pistes-pgsnapshot-tmp -c "CREATE EXTENSION hstore;" # only required for hstore support
    psql -U xapi -d pistes-pgsnapshot-tmp -c "CREATE EXTENSION pg_trgm;"
    echo "ALTER USER xapi WITH PASSWORD 'xapi';" |psql -U admin -d pistes-pgsnapshot-tmp
    
    psql -U xapi -d pistes-pgsnapshot-tmp -f /usr/share/doc/osmosis/examples/pgsnapshot_schema_0.6.sql
    psql -U xapi -d pistes-pgsnapshot-tmp -f /usr/share/doc/osmosis/examples/pgsnapshot_schema_0.6_bbox.sql
    psql -U xapi -d pistes-pgsnapshot-tmp -f /usr/share/doc/osmosis/examples/pgsnapshot_schema_0.6_linestring.sql
    psql -U xapi -d pistes-pgsnapshot-tmp -f /usr/share/doc/osmosis/examples/pgsnapshot_schema_0.6_action.sql
    psql -U xapi -d pistes-pgsnapshot-tmp -f /home/admin/Planet/config/pgsnapshot_schema_0.6_relations_geometry.sql
    psql -U xapi -d pistes-pgsnapshot-tmp -f /home/admin/Planet/config/pgsnapshot_schema_0.6_names.sql
    psql -U xapi -d pistes-pgsnapshot-tmp -f /home/admin/Planet/config/pgsnapshot_schema_0.6_relations_types.sql

#~ fi
H=/home/admin/

WORK_DIR=${H}Planet/

#~ osmosis="osmosis -q"
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
    osmosis --truncate-pgsql host="localhost" user="xapi" password="xapi" \
    database=$DBTMP
    if [ $? -ne 0 ]
    then
        echo $(date)' truncate DB failed'
    fi
    osmosis --read-xml-change ${PLANET_DIR}landuse.osc \
    --sort-change --simplify-change \
    --read-xml ${PLANET_DIR}planet_pistes-osmium.osm \
    --apply-change \
    --write-pgsql host="localhost" database=$DBTMP user="xapi" password="xapi"
    if [ $? -ne 0 ]
    then
        echo $(date)' Osmosis failed to update pgsnapshot DB'
    fi

    echo $(date)' Drop pgsnapshot DB'
    dropdb --if-exists -U xapi $DB
    echo $(date)' Create pgsnapshot DB'
	createdb -U xapi -T $DBTMP $DB
else 
    echo $(date)' planet_pistes.osm empty'
fi

${TOOLS_DIR}scripts/./resort_list.py > ${PLANET_DIR}resorts.json
TESTSIZE=$(stat -c%s ${PLANET_DIR}resorts.json)
if [ $TESTSIZE -gt 10 ]
then 
	echo $(date)' resorts.json ok'
	cp ${PLANET_DIR}resorts.json /var/www/data

else 
    echo $(date)' resorts.json empty'
fi
cat /home/admin/Planet/log/daily-osmium.log | msmtp admin@opensnowmap.org

${TOOLS_DIR}./07-routing_db.sh
exit 0
