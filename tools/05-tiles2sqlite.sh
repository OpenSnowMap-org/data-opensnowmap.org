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
echo $(date)' Sqlite generation starting '
${TOOLS_DIR}./tile-list-not-unique.py -f ${PLANET_DIR}planet_pistes.osm -o ${TMP_DIR}tilesz16.lst -Z 14
cat ${TMP_DIR}tilesz14.lst | sort | uniq > ${TMP_DIR}uniq_z14.lst
${TOOLS_DIR}./render2sqlite.py ${TMP_DIR}uniq_z16.lst ${PLANET_DIR}opensnowmap.org-z14.sqlitedb
