#!/bin/bash

#______________________________________________________________________
# This script filters a planet.o5m file to keep piste:type=nordic
# elements only in one file, and piste:type and aerialways in another
# It also create daily, weekly and monthly change files along with tsv
# file containing the newly created nodes.
#______________________________________________________________________
if  [ -d "/home/admin/" ]; then
	H=/home/admin/
else
	H=/home/website/
fi
WORK_DIR=${H}Planet/
osmosis="$H/src/osmosis/bin/osmosis -q"

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
./osmfilter ${PLANET_DIR}planet.o5m --keep="bridge= or whitewater:section_grade= or whitewater:section_name= or whitewater:rapid_grade= or whitewater:rapid_name= or whitewater= or sport=canoe or kayak_rental= or route=canoe" > ${TMP_DIR}planet_ww.osm
if [ $? -ne 0 ]
then
    echo $(date)' FAILED to filter planet ww file'
    exit 2
else
    echo $(date)' Planet pistes file ww filtered '
fi
mv ${TMP_DIR}planet_ww.osm ${PLANET_DIR}planet_ww.osm

#-----------------------------------------------------------------------
#Publish pistes extract
#-----------------------------------------------------------------------
gzip -c  ${PLANET_DIR}planet_ww.osm > ${DOWNLOADS_DIR}planet_ww.osm.gz
echo $(date)' latest planet_ww.osm published'

./03-db_update-ww.sh
