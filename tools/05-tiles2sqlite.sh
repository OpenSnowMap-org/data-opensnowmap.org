#!/bin/bash

#______________________________________________________________________
# 
#______________________________________________________________________

if  [ -d "/home/admin/" ]; then
	H=/home/admin/
else
	H=/home/website/
fi
WORK_DIR=${H}Planet/
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
echo $(date)' Asia '
${TOOLS_DIR}./tile-list-from-db.py -o ${TMP_DIR}list.lst -Z 16 -j ${TOOLS_DIR}geojson/Asia_Oceania_Africa.geojson
cat ${TMP_DIR}list.lst | sort | uniq > ${TMP_DIR}uniq.lst
nice -n19 ${TOOLS_DIR}./render2sqlite.py ${TMP_DIR}uniq.lst ${PLANET_DIR}opensnowmap.org-Asia_Oceania_Africa-z16.sqlitedb

echo $(date)' Americas '
${TOOLS_DIR}./tile-list-from-db.py -o ${TMP_DIR}list.lst -Z 16 -j ${TOOLS_DIR}geojson/Americas.geojson
cat ${TMP_DIR}list.lst | sort | uniq > ${TMP_DIR}uniq.lst
nice -n19 ${TOOLS_DIR}./render2sqlite.py ${TMP_DIR}uniq.lst ${PLANET_DIR}opensnowmap.org-Americas-z16.sqlitedb

echo $(date)' Northern_Europe '
${TOOLS_DIR}./tile-list-from-db.py -o ${TMP_DIR}list.lst -Z 16 -j ${TOOLS_DIR}geojson/Northern_Europe.geojson
cat ${TMP_DIR}list.lst | sort | uniq > ${TMP_DIR}uniq.lst
nice -n19 ${TOOLS_DIR}./render2sqlite.py ${TMP_DIR}uniq.lst ${PLANET_DIR}opensnowmap.org-Northern_Europe-z16.sqlitedb

echo $(date)' Southern Europe '
${TOOLS_DIR}./tile-list-from-db.py -o ${TMP_DIR}list.lst -Z 16 -j ${TOOLS_DIR}geojson/Southern_Europe.geojson
cat ${TMP_DIR}list.lst | sort | uniq > ${TMP_DIR}uniq.lst
nice -n19 ${TOOLS_DIR}./render2sqlite.py ${TMP_DIR}uniq.lst ${PLANET_DIR}opensnowmap.org-Southern_Europe-z16.sqlitedb

mv ${PLANET_DIR}*.sqlitedb ${H}downloadable/
