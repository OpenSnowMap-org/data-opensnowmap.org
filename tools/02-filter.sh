#!/bin/bash

#______________________________________________________________________
# This script filters a planet.o5m file to keep piste:type=nordic
# elements only in one file, and piste:type and aerialways in another
# It also create daily, weekly and monthly change files along with tsv
# file containing the newly created nodes.
#______________________________________________________________________
osmosis="/home/admin/src/osmosis/bin/osmosis -q"
WORK_DIR=/home/admin/Planet/
# This script log
LOGFILE=${WORK_DIR}log/planet_update.log
# Directory where the planet file is stored
PLANET_DIR=${WORK_DIR}data/
TMP_DIR=${WORK_DIR}tmp/
TOOLS_DIR=${WORK_DIR}tools/
ARCHIVE_DIR=${WORK_DIR}archives/
DOWNLOADS_DIR=/home/admin/downloadable/

CONFIG_DIR=${WORK_DIR}config/
cd ${TOOLS_DIR}

echo $(date)' ######################### '
echo $(date)' Filtering starting '
#______________________________________________________________________
# Filtering pistes
./osmfilter ${PLANET_DIR}planet.o5m --keep="piste:type= or aerialway= or railway=funicular or site=piste or sport=ski_jump or sport=skating or sport=ski_jump_take_off" > ${TMP_DIR}planet_pistes.osm
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
./osmfilter ${PLANET_DIR}planet_pistes.osm --keep="site=piste" > ${TMP_DIR}planet_pistes_sites.osm
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
        $osmosis \
        --rx $daily_file \
        --rx $yesterday_file \
        --dc \
        --wxc ${PLANET_DIR}daily.osc
        echo $(date)' daily.osc done'
    else
        echo $(date)' no yesterday file found' $yesterday_file
    fi
# Create weekly.osc
    if [ -f $lastweek_file ];
    then
        echo $(date)' lastweek file found' $lastweek_file
        $osmosis \
        --rx $daily_file \
        --rx $lastweek_file \
        --dc \
        --wxc ${PLANET_DIR}weekly.osc
        echo $(date)' weekly.osc done'
    else
        echo $(date)' no lastweek file found' $lastweek_file
    fi
# Create monthly.osc
    if [ -f $lastmonth_file ];
    then
        echo $(date)' lastmonth file found' $lastmonth_file
        $osmosis \
        --rx $daily_file \
        --rx $lastmonth_file \
        --dc \
        --wxc ${PLANET_DIR}monthly.osc
        echo $(date)' monthly.osc done'
    else
        echo $(date)' no lastmonth file found' $lastmonth_file
    fi
else
    echo $(date)' NO DAILY FILE FOUND !!'$daily_file
fi

#-----------------------------------------------------------------------
#Create new nodes files weekly.tsv, daily.tsv, monthly.tsv for openlayers
#-----------------------------------------------------------------------
if [ -f ${PLANET_DIR}daily.osc ];
then
    echo $(date)' daily file found'
    cat ${PLANET_DIR}daily.osc | grep -o 'lat="[0-9.]*" lon="[0-9.]*"' > ${TMP_DIR}tmp1
    sed s/lat=\"// ${TMP_DIR}tmp1 > ${TMP_DIR}tmp2
    sed s/\lon=\"// ${TMP_DIR}tmp2 > ${TMP_DIR}tmp1
    sed s/\"//g ${TMP_DIR}tmp1 > ${TMP_DIR}tmp2
    echo "point" > ${PLANET_DIR}daily.tsv
    sed s/[[:space:]]/,/g ${TMP_DIR}tmp2 >> ${PLANET_DIR}daily.tsv
    echo $(date)' daily.tsv done'
else
    echo $(date)' no daily file found'
fi
#---
if [ -f ${PLANET_DIR}weekly.osc ];
then
    echo $(date)' weekly file found'
    cat ${PLANET_DIR}weekly.osc | grep -o 'lat="[0-9.]*" lon="[0-9.]*"' > ${TMP_DIR}tmp1
    sed s/lat=\"// ${TMP_DIR}tmp1 > ${TMP_DIR}tmp2
    sed s/\lon=\"// ${TMP_DIR}tmp2 > ${TMP_DIR}tmp1
    sed s/\"//g ${TMP_DIR}tmp1 > ${TMP_DIR}tmp2
    echo "point" > ${PLANET_DIR}weekly.tsv
    sed s/[[:space:]]/,/g ${TMP_DIR}tmp2 >> ${PLANET_DIR}weekly.tsv
    echo $(date)' weekly.tsv done'
else
    echo $(date)' no weekly file found'
fi
#---
if [ -f ${PLANET_DIR}monthly.osc ];
then
    echo $(date)' monthly file found'
    cat ${PLANET_DIR}monthly.osc | grep -o 'lat="[0-9.]*" lon="[0-9.]*"' > ${TMP_DIR}tmp1
    sed s/lat=\"// ${TMP_DIR}tmp1 > ${TMP_DIR}tmp2
    sed s/\lon=\"// ${TMP_DIR}tmp2 > ${TMP_DIR}tmp1
    sed s/\"//g ${TMP_DIR}tmp1 > ${TMP_DIR}tmp2
    echo "point" > ${PLANET_DIR}monthly.tsv
    sed s/[[:space:]]/,/g ${TMP_DIR}tmp2 >> ${PLANET_DIR}monthly.tsv
    echo $(date)' monthly.tsv done'
else
    echo $(date)' no monthly file found'
fi

cp ${PLANET_DIR}*.tsv \
       /var/www/www.opensnowmap.org/data/
#-----------------------------------------------------------------------
# remove temporary files
#-----------------------------------------------------------------------
rm ${TMP_DIR}*
echo $(date)' filter.sh DONE'

./03-db_update.sh
