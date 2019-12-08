#!/bin/bash

#______________________________________________________________________
# This script filters a planet.o5m file to keep piste:type=nordic
# elements only in one file, and piste:type and aerialways in another
# It also create daily, weekly and monthly change files along with tsv
# file containing the newly created nodes.
#______________________________________________________________________

H=/home/admin/

WORK_DIR=${H}Planet/

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

echo $(date)' ######################### '
echo $(date)' Filtering starting '
#______________________________________________________________________
# Filtering pistes
osmfilter ${PLANET_DIR}planet.o5m --keep="piste:type= or aerialway= or railway=funicular or railway=incline or site=piste or landuse=winter_sports or sport=ski_jump or sport=ski_jump_take_off or man_made=snow_cannon or sport=skating or sport=ice_skating or leisure=ice_rink or sport=ice_stock or sport=curling or sport=ice_hockey " > ${TMP_DIR}planet_pistes.osm
# consider or leisure=stadium or leisure=pitch or leisure=sports_centre or leisure=track, but we have to filter changeset for .tsv generation
if [ $? -ne 0 ]
then
    echo $(date)' FAILED to filter planet file'
    exit 2
else
    echo $(date)' Planet pistes file filtered '
fi
mv ${TMP_DIR}planet_pistes.osm ${PLANET_DIR}planet_pistes.osm
#______________________________________________________________________
# Filtering sites
osmfilter ${PLANET_DIR}planet_pistes.osm --keep="site=piste" > ${TMP_DIR}planet_pistes_sites.osm
if [ $? -ne 0 ]
then
    echo $(date)' FAILED to filter planet file'
    exit 2
else
    echo $(date)' Pistes sites file filtered '
fi
#---
mv ${TMP_DIR}planet_pistes_sites.osm ${PLANET_DIR}planet_pistes_sites.osm
echo $(date)' planet_pistes.osm and planet_sites.osm extracted'

#-----------------------------------------------------------------------
#Create archive files
#-----------------------------------------------------------------------

last=$(tail -1 ${PLANET_DIR}state.txt  | sed 's/\([0-9-]*\).*/\1/')


gzip -c  ${PLANET_DIR}planet_pistes.osm > ${ARCHIVE_DIR}planet_pistes-$last.osm.gz
echo $(date)' latest planet_pistes.osm archived'

#-----------------------------------------------------------------------
#Publish pistes extract
#-----------------------------------------------------------------------
gzip -c  ${PLANET_DIR}planet_pistes.osm > ${DOWNLOADS_DIR}planet_pistes.osm.gz
cp ${PLANET_DIR}state.txt ${DOWNLOADS_DIR}planet_pistes-state.txt
echo $(date)' latest planet_pistes.osm published'

#-----------------------------------------------------------------------
#Create change files
#-----------------------------------------------------------------------

today=$(date --date="today" +%Y-%m-%d)
yesterday=$(date --date="1 day ago" +%Y-%m-%d)
lastweek=$(date --date="1 week ago" +%Y-%m-%d)
lastmonth=$(date --date="1 month ago" +%Y-%m-%d)

daily_file=${PLANET_DIR}planet_pistes.osm
yesterday_file=${ARCHIVE_DIR}planet_pistes-$yesterday.osm.gz
lastweek_file=${ARCHIVE_DIR}planet_pistes-$lastweek.osm.gz
lastmonth_file=${ARCHIVE_DIR}planet_pistes-$lastmonth.osm.gz

if [ -f $daily_file ];
then
    echo $(date)' daily file found '$daily_file
# Create daily.osc
    if [ -f $yesterday_file ];
    then
        echo $(date)' yesterday file found' $yesterday_file
        osmconvert $yesterday_file $daily_file --diff -o=${PLANET_DIR}daily.osc
        echo $(date)' daily.osc done'
        touch ${PLANET_DIR}dailyok
    else
        echo $(date)' no yesterday file found' $yesterday_file
    fi
# Create weekly.osc
    if [ -f $lastweek_file ];
    then
        echo $(date)' lastweek file found' $lastweek_file
        osmconvert $lastweek_file $daily_file --diff -o=${PLANET_DIR}weekly.osc
        echo $(date)' weekly.osc done'
    else
        echo $(date)' no lastweek file found' $lastweek_file
    fi
# Create monthly.osc
    if [ -f $lastmonth_file ];
    then
        echo $(date)' lastmonth file found' $lastmonth_file
        osmconvert $lastmonth_file $daily_file --diff -o=${PLANET_DIR}monthly.osc
        echo $(date)' monthly.osc done'
    else
        echo $(date)' no lastmonth file found' $lastmonth_file
    fi
else
    echo $(date)' NO DAILY FILE FOUND !!'$daily_file
fi

#-----------------------------------------------------------------------
# remove temporary files
#-----------------------------------------------------------------------
rm ${TMP_DIR}*
echo $(date)' filter.sh DONE'

./03-db_update.sh
