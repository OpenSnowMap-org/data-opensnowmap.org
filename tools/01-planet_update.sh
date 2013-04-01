#!/bin/bash

#______________________________________________________________________
# This script is intended to keep a planet.osm.gz file up to date with
# daily diffs. 
# It is not necessary to run the scipt every day.
# It will exit 2 on error, 1 if there is nothing to do, and 0 if update 
# is succesfull.
#______________________________________________________________________

WORK_DIR=/home/website/Planet/
# This script log
LOGFILE=${WORK_DIR}log/planet_update.log
# Directory where the planet file is stored
PLANET_DIR=${WORK_DIR}data/
TMP_DIR=${WORK_DIR}tmp/
TOOLS_DIR=${WORK_DIR}tools/
cd ${TOOLS_DIR}

echo $(date)' ######################### '

#______________________________________________________________________

echo $(date)' ######################### '
echo $(date)' Update starting '

#______________________________________________________________________
# Backup old files
#~ cp ${PLANET_DIR}state.txt ${PLANET_DIR}last_state.txt

#______________________________________________________________________
# Update planet

./osmupdate ${PLANET_DIR}planet.o5m ${PLANET_DIR}new-planet.o5m
if [ $? -ne 0 ]
then
    echo $(date)' FAILED to update planet file'
    exit 2
else
    echo $(date)' Planet file updated '
    mv ${PLANET_DIR}new-planet.o5m ${PLANET_DIR}planet.o5m
fi
#______________________________________________________________________
# Update timestamp
./osmconvert -v ${PLANET_DIR}planet.o5m --out-timestamp > ${PLANET_DIR}state.txt

# remove files
rm ${TMP_DIR}*
#______________________________________________________________________
${WORK_DIR}tools/./02-filter.sh
