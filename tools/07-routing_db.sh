#~ sudo apt install postgresql-11-pgrouting 
#~ -> buster: postgresql-11-pgrouting (2.6.2-1)

#~ sudo apt install osm2pgrouting
#~ -> buster: osm2pgrouting (2.3.6-1) 

#~ sudo apt install pyosmium
#~ -> buster: pyosmium (2.15.1-1) 

H=/home/admin/
WORK_DIR=${H}Planet/
USER=admin

#~ H=/home/yves/
#~ WORK_DIR=${H}OPENSNOWMAP/Planet.git/
#~ USER=yves

cd ${WORK_DIR}

# This script log
LOGFILE=${WORK_DIR}log/planet_update.log
# Directory where the planet file is stored
PLANET_DIR=${WORK_DIR}data/
TMP_DIR=${WORK_DIR}tmp/
TOOLS_DIR=${WORK_DIR}tools/
CONFIG_DIR=${WORK_DIR}config/
ARCHIVE_DIR=${WORK_DIR}archives/

DBROUTING=routing
DBROUTINGTMP=routing-tmp
# Note: only tags relevant for osm2pgrouting mapconfig_ski.xml
# are kept.
# In particular, ways such as https://www.openstreetmap.org/way/28999320
# or https://www.openstreetmap.org/way/35004930
# were not imported, no reason found.
# oneway=* tags are discarded, this should be fixed somehow.
# Otherwise, ways and nodes are kept in case they are relation members.
#~ python routing_tag_transform.py planet_pistes.osm planet_pistes_2.osm

dropdb $DBROUTINGTMP
createdb $DBROUTINGTMP
psql --dbname $DBROUTINGTMP -U $USER -c 'CREATE EXTENSION postgis'
psql --dbname $DBROUTINGTMP -U $USER -c 'CREATE EXTENSION pgRouting'
psql --dbname $DBROUTINGTMP -U $USER -c 'CREATE EXTENSION hstore'

rm ${PLANET_DIR}planet_pistes_routing_filtered.osm
python ${TOOLS_DIR}scripts/routing_tag_transform.py ${PLANET_DIR}planet_pistes.osm ${PLANET_DIR}planet_pistes_routing_filtered.osm

# Tabs removal see https://github.com/pgRouting/osm2pgrouting/issues/259
sed -i "s/version=\"[0-9]+\" timestamp=\"[^\"]+\" changeset=\"[0-9]+\" uid=\"[0-9]+\" user=\"[^\"]+\"//g" ${PLANET_DIR}planet_pistes_routing_filtered.osm
sed -r "s/version=\"[0-9]+\"//g" ${PLANET_DIR}planet_pistes_routing_filtered.osm -i 
sed -r  "s/timestamp=\"[^\"]+\"//g" ${PLANET_DIR}planet_pistes_routing_filtered.osm -i
sed -r "s/changeset=\"[0-9]+\"//g" ${PLANET_DIR}planet_pistes_routing_filtered.osm -i
sed -r "s/uid=\"[0-9]+\"//g" ${PLANET_DIR}planet_pistes_routing_filtered.osm -i
sed -r "s/user=\"[^\"]+\"//g" ${PLANET_DIR}planet_pistes_routing_filtered.osm -i
sed -i $'s/&#x9;/ /g' ${PLANET_DIR}planet_pistes_routing_filtered.osm

/usr/bin/osm2pgrouting --f ${PLANET_DIR}planet_pistes_routing_filtered.osm --conf ${CONFIG_DIR}mapconfig_ski.xml --dbname $DBROUTINGTMP --username $USER --clean --chunk 100000

echo "select count(*) from ways;" | psql -d $DBROUTINGTMP -U $USER
    #~ if (m_oneWay == "YES") return "1";
    #~ if (m_oneWay == "NO") return  "2";
    #~ if (m_oneWay == "REVERSIBLE") return  "3";
    #~ if (m_oneWay == "REVERSED") return "-1";
    #~ if (m_oneWay == "UNKNOWN") return "0";

# By default, cost is the lengh of the way for shortest route rouring:
echo "UPDATE ways SET cost = length_m, reverse_cost = length_m;" | psql -d $DBROUTINGTMP -U $USER
# lifts :
# Default oneway lifts:
echo "UPDATE ways SET reverse_cost = -1 
WHERE tag_id IN (202, 203, 204, 205, 206, 207, 209, 210)
AND oneway NOT IN ('NO','REVERSED','REVERSIBLE')
;" | psql -d $DBROUTINGTMP -U $USER
# When specified:
echo "UPDATE ways SET cost = -1 
WHERE tag_id IN (201, 202, 203, 204, 205, 206, 207, 208, 209, 210)
AND oneway IN ('REVERSED','REVERSIBLE')
;" | psql -d $DBROUTINGTMP -U $USER
echo "UPDATE ways SET reverse_cost = -1 
WHERE tag_id IN (201,208)
AND oneway IN ('YES')
;" | psql -d $DBROUTINGTMP -U $USER
# Downhill default:
echo "UPDATE ways SET reverse_cost = 20 * length_m 
WHERE tag_id IN (101,106, 105, 111)
AND oneway NOT IN ('NO','REVERSED','REVERSIBLE')
;" | psql -d $DBROUTINGTMP -U $USER
echo "UPDATE ways SET cost = 20 * length_m 
WHERE tag_id IN (101,106, 105, 111)
AND oneway IN ('REVERSED','REVERSIBLE')
;" | psql -d $DBROUTINGTMP -U $USER
# rest When specified
echo "UPDATE ways SET reverse_cost = -1 
WHERE tag_id IN (100,101,102,103,104,105,106,107,108,109,110,111,112)
AND oneway IN ('YES')
;" | psql -d $DBROUTINGTMP -U $USER
echo "UPDATE ways SET cost = -1 
WHERE tag_id IN (100,101,102,103,104,105,106,107,108,109,110,111,112)
AND oneway IN ('REVERSED','REVERSIBLE')
;" | psql -d $DBROUTINGTMP -U $USER

echo "SELECT
    pg_terminate_backend (pg_stat_activity.pid)
FROM
    pg_stat_activity
WHERE
    pg_stat_activity.datname = 'routing';" | psql -d $DBROUTINGTMP -U $USER

echo $(date)' replace routing DB'
dropdb -U $USER $DBROUTING
createdb -U $USER -T $DBROUTINGTMP $DBROUTING

