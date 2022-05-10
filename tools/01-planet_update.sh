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
LOGFILE=${WORK_DIR}log/planet_update.log
# Directory where the planet file is stored
PLANET_DIR=${WORK_DIR}data/
TMP_DIR=${WORK_DIR}tmp/
TOOLS_DIR=${WORK_DIR}tools/
cd ${TOOLS_DIR}
ARCHIVE_DIR=${WORK_DIR}archives/
DOWNLOADS_DIR=${H}downloadable/
CONFIG_DIR=${WORK_DIR}config/
mkdir -p ${PLANET_DIR}
mkdir -p ${TMP_DIR}
mkdir -p ${ARCHIVE_DIR}
mkdir -p ${CONFIG_DIR}

#______________________________________________________________________

echo $(date)' ######################### '
echo $(date)' Update starting '

#______________________________________________________________________
# Update planet

osmupdate ${PLANET_DIR}planet.o5m ${TMP_DIR}new-planet.o5m
#~ pyosmium-up-to-date ${PLANET_DIR}planet.o5m --outfile ${TMP_DIR}new-planet.pbf --tmpdir ${TMP_DIR}
if [ $? -ne 0 ]
then
    echo $(date)' FAILED to update planet file'
    exit 2
else
    echo $(date)' Planet file updated '
    #~ osmconvert ${TMP_DIR}new-planet.pbf --out-o5m -o=${PLANET_DIR}planet.o5m 
    # limit speed to 20MB/s in order to let some io to apache/mod_tile
    rsync -a --bwlimit=100000 ${TMP_DIR}new-planet.o5m ${PLANET_DIR}planet.o5m
    #mv ${TMP_DIR}new-planet.o5m ${PLANET_DIR}planet.o5m
    echo $(date)' Planet file moved to planet directory '
fi
#______________________________________________________________________
# Update timestamp
osmconvert -v ${PLANET_DIR}planet.o5m --out-timestamp > ${PLANET_DIR}state.txt
echo $(date)' Timestamp extracted '

# remove tmp files
rm ${TMP_DIR}*
#______________________________________________________________________
${WORK_DIR}tools/./02-filter.sh
