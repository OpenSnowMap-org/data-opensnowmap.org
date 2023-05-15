#!/bin/bash

#______________________________________________________________________
# This script is intended to keep a planet.osm.gz file up to date with
# daily diffs. 
# It is not necessary to run the scipt every day.
# It will exit 2 on error, 1 if there is nothing to do, and 0 if update 
# is succesfull.
#______________________________________________________________________
H=/home/admin/

WORK_DIR=${H}Planet/

# This script log
LOGFILE=${WORK_DIR}log/planet_update-osmium.log
# Directory where the planet file is stored
PLANET_DIR=${WORK_DIR}data/
TMP_DIR=${WORK_DIR}tmp/
TOOLS_DIR=${WORK_DIR}tools/
ARCHIVE_DIR=${WORK_DIR}archives/
DOWNLOADS_DIR=${H}downloadable/
CONFIG_DIR=${WORK_DIR}config/
cd ${TOOLS_DIR}

echo $(date)' ######################### '
echo $(date)' Update starting '

#~ To start with a fresh Planet:
#~ cd ${PLANET_DIR}
#~ wget https://planet.openstreetmap.org/pbf/planet-latest.osm.pbf
#~ mv ${PLANET_DIR}planet-latest.osm.pbf ${PLANET_DIR}old_planet-osmium.pbf

#~ Daily update:
mv --force ${PLANET_DIR}updated_planet-osmium.pbf ${PLANET_DIR}old_planet-osmium.pbf

export OSMIUM_POOL_THREADS=1
sequenceId=$(cat ${PLANET_DIR}sequence.state)
timestamp=$(${TOOLS_DIR}scripts/getTimestampFromSequenceID.py $sequenceId https://planet.osm.org/replication/hour/)
echo $(date)" - Starting update from "$timestamp", sequence "$sequenceId 
    
date
echo "*******************************************"
echo "Create diff file"
echo "*******************************************"

rm ${PLANET_DIR}change_file.osc.gz
pyosmium-get-changes -v -s 1024 --format osc.gz --server https://planet.osm.org/replication/hour/ -f ${PLANET_DIR}sequence.state -o ${PLANET_DIR}change_file.osc.gz 

if [ $? -ne 0 ]; then
    echo $(date)' Changefile build failed'
    echo $sequenceId > ${PLANET_DIR}sequence.state
    exit 1
fi

#~ pyosmium-up-to-date -v --tmpdir ${TMP_DIR} --ignore-osmosis-headers -s 4096 -o ${TMP_DIR}updated_planet-osmium.pbf ${PLANET_DIR}old_planet-osmium.pbf 
osmium apply-changes ${PLANET_DIR}old_planet-osmium.pbf ${PLANET_DIR}change_file.osc.gz -o ${TMP_DIR}updated_planet-osmium.pbf

status=$?
if [ $status -ne 0 ]; then
    echo $(date)' Applying change failed'
    exit 2
fi
 

echo $(date)' Planet file updated '
rsync -a --bwlimit=50000 ${TMP_DIR}updated_planet-osmium.pbf ${PLANET_DIR}updated_planet-osmium.pbf
if [ $? -ne 0 ]; then
    echo $(date)' Rsync error, exiting '
else
    echo $(date)' Planet file moved to planet directory '
fi

#______________________________________________________________________
# Update timestamp
#pyosmium-get-changes -v --server https://planet.osm.org/replication/hour/ --start-osm-data ${PLANET_DIR}/updated_planet-osmium.pbf -f ${PLANET_DIR}sequence.state 
sequenceId=$(cat ${PLANET_DIR}/sequence.state)
timestamp=$(${TOOLS_DIR}scripts/getTimestampFromSequenceID.py $sequenceId https://planet.osm.org/replication/hour/)
echo $timestamp> ${PLANET_DIR}state.txt

#echo $(date)' Timestamp extracted '
echo $(date)' Sequence Id: '$sequenceId
echo $(date)' Timestamp: '$timestamp

echo $(date)' ######################### '
echo $(date)' Filtering starting '
# remove tmp files
rm ${TMP_DIR}*

#______________________________________________________________________
# This script filters a planet.o5m file to keep piste:type=nordic
# elements only in one file, and piste:type and aerialways in another
# It also create daily, weekly and monthly change files along with tsv
# file containing the newly created nodes.
#______________________________________________________________________

echo $(date)' ######################### '
echo $(date)' Filtering starting '
#______________________________________________________________________
# Filtering pistes

#~ OSMIUM_POOL_THREADS=2

#~ nice -n 19 
osmium tags-filter ${PLANET_DIR}updated_planet-osmium.pbf --output-format=osm -o ${TMP_DIR}planet_pistes-osmium.osm --overwrite --fsync --expressions=${CONFIG_DIR}osmiumTagFilter.conf 

if [ $? -ne 0 ]
then
    echo $(date)' FAILED to filter planet file'
    exit 2
else
    echo $(date)' Planet pistes file filtered '
    mv --force ${PLANET_DIR}planet_pistes-osmium.osm ${PLANET_DIR}planet_pistes-osmium-old.osm
    mv --force ${TMP_DIR}planet_pistes-osmium.osm ${PLANET_DIR}planet_pistes-osmium.osm
fi
#______________________________________________________________________
# Filtering sites


osmium tags-filter ${PLANET_DIR}planet_pistes-osmium.osm --output-format=osm -o ${TMP_DIR}planet_pistes_sites-osmium.osm --overwrite --fsync site=piste
if [ $? -ne 0 ]
then
    echo $(date)' FAILED to filter planet file'
    exit 2
else
    echo $(date)' Pistes sites file filtered '
    mv --force ${PLANET_DIR}planet_pistes_sites-osmium.osm ${PLANET_DIR}planet_pistes_sites-osmium-old.osm
    mv --force ${TMP_DIR}planet_pistes_sites-osmium.osm ${PLANET_DIR}planet_pistes_sites-osmium.osm
fi

echo $(date)' planet_pistes.osm and planet_sites.osm extracted'


#-----------------------------------------------------------------------
#Create archive files
#-----------------------------------------------------------------------

last=$(tail -1 ${PLANET_DIR}state.txt  | sed 's/\([0-9-]*\).*/\1/')


#~ gzip -c  ${PLANET_DIR}planet_pistes-osmium.osm > ${ARCHIVE_DIR}planet_pistes-osmium-$last.osm.gz
#~ echo $(date)' latest planet_pistes.osm archived'

#-----------------------------------------------------------------------
#Publish pistes extract
#-----------------------------------------------------------------------
gzip -c  ${PLANET_DIR}planet_pistes-osmium.osm > ${DOWNLOADS_DIR}planet_pistes.osm.gz
cp ${PLANET_DIR}state.txt ${DOWNLOADS_DIR}planet_pistes-state.txt
echo $(date)' latest planet_pistes.osm published'

#-----------------------------------------------------------------------
#Create change files
#-----------------------------------------------------------------------

today=$(date --date="today" +%Y-%m-%d)
yesterday2=$(date --date="2 day ago" +%Y-%m-%d)
yesterday=$(date --date="1 day ago" +%Y-%m-%d)
lastweek=$(date --date="1 week ago" +%Y-%m-%d)
lastmonth=$(date --date="1 month ago" +%Y-%m-%d)

daily_file=${PLANET_DIR}planet_pistes-osmium.osm
yesterday_file=${ARCHIVE_DIR}planet_pistes-osmium-$yesterday.osm.gz
yesterday2_file=${ARCHIVE_DIR}planet_pistes-osmium-$yesterday2.osm.gz
lastweek_file=${ARCHIVE_DIR}planet_pistes-osmium-$lastweek.osm.gz
lastmonth_file=${ARCHIVE_DIR}planet_pistes-osmium-$lastmonth.osm.gz


gzip -c  ${PLANET_DIR}planet_pistes-osmium.osm > ${ARCHIVE_DIR}planet_pistes-osmium-$today.osm.gz
echo $(date)' latest planet_pistes.osm archived'

if [ -f $daily_file ];
then
    echo $(date)' daily file found '$daily_file
# Create daily.osc
    if [ -f $yesterday_file ];
    then
        echo $(date)' yesterday file found' $yesterday_file
        osmium derive-changes $yesterday_file $daily_file --output=${PLANET_DIR}daily-osmium.osc --overwrite 
        echo $(date)' daily.osc done'
        touch ${PLANET_DIR}dailyok-osmium
    else

            if [ -f $yesterday2_file ];
            then
                echo $(date)' yesterday2 file found' $yesterday2_file
                osmium derive-changes $yesterday2_file $daily_file --output=${PLANET_DIR}daily-osmium.osc --overwrite 
                echo $(date)' daily.osc done'
                touch ${PLANET_DIR}dailyok-osmium
            else
                echo $(date)' no yesterday file found' $yesterday_file
            fi
    fi
# Create weekly.osc
    if [ -f $lastweek_file ];
    then
        echo $(date)' lastweek file found' $lastweek_file
        osmium derive-changes $lastweek_file $daily_file --output=${PLANET_DIR}weekly-osmium.osc --overwrite 
        echo $(date)' weekly.osc done'
    else
        echo $(date)' no lastweek file found' $lastweek_file
    fi
# Create monthly.osc
    if [ -f $lastmonth_file ];
    then
        echo $(date)' lastmonth file found' $lastmonth_file
        osmium derive-changes $lastmonth_file $daily_file --output=${PLANET_DIR}monthly-osmium.osc --overwrite 
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
#~ exit 0

