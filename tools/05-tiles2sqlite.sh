#!/bin/bash

#______________________________________________________________________
# 
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
${TOOLS_DIR}./tile-list-from-db.py -o ${TMP_DIR}z16.lst -Z 16
cat ${TMP_DIR}z16.lst | sort | uniq > ${TMP_DIR}uniq_z16.lst
nice -n19 ${TOOLS_DIR}./render2sqlite.py ${TMP_DIR}uniq_z16.lst ${PLANET_DIR}opensnowmap.org-z16.sqlitedb
