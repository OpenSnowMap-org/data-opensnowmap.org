#______________________________________________________________________
# This script process piste.osm to usable osmand obf for android devices
#______________________________________________________________________
WORK_DIR=/home/website/Planet/
cd ${WORK_DIR}
# This script log
LOGFILE=${WORK_DIR}log/planet_update.log
# Directory where the planet file is stored
PLANET_DIR=${WORK_DIR}data/
TMP_DIR=${WORK_DIR}tmp/
TOOLS_DIR=${WORK_DIR}tools/

# Pre-process osm file
echo $(date)' osmand_pistes.py ...'
${TOOLS_DIR}./osmand_pistes.py ${PLANET_DIR}planet_pistes.osm ${WORK_DIR}osmand_data/world-ski.osm
if [ $? -ne 0 ]
then
    echo $(date)' FAILED osmand_pistes.py'
    exit 3
else echo $(date)' osmand_pistes.py succeed '
fi

# Run OsmAndMapCreator
echo $(date)' OsmAndMapCreator '

cd ${TOOLS_DIR}OsmAndMapCreator
java -Djava.util.logging.config.file=logging.properties -Xms512M -Xmx2048M -cp "./OsmAndMapCreator.jar:./lib/*.jar" net.osmand.data.index.IndexBatchCreator ./batch.xml 


$osmand > /dev/null 2>&1  
if [ $? -ne 0 ]
then
    echo $(date)' FAILED OsmAndMapCreator'
    exit 4
else echo $(date)' OsmAndMapCreator succeed '
fi

# Count piste length
echo $(date)' computing pistes way length'
${TOOLS_DIR}./pistes_length_fr.sh > ${PLANET_DIR}pistes_length.fr.txt
if [ $? -ne 0 ]
then
    echo $(date)' FAILED computing pistes way length'
    exit 5
else echo $(date)' computing pistes way length succeed '
fi
${TOOLS_DIR}./pistes_length_en.sh > ${PLANET_DIR}pistes_length.en.txt
if [ $? -ne 0 ]
then
    echo $(date)' FAILED computing pistes way length'
    exit 5
else echo $(date)' computing pistes way length succeed '
fi
       
cp ${PLANET_DIR}pistes_length.en.txt \
       /var/www/www.opensnowmap.org/data/pistes_length.en.txt
cp ${PLANET_DIR}pistes_length.fr.txt \
       /var/www/www.opensnowmap.org/data/pistes_length.fr.txt
       
# make world-ski.obf avail for download

gzip -c ${WORK_DIR}osmand_data/World-ski_2.obf > /home/website/downloadable/World-ski_2.obf.gz
zip -j /home/website/downloadable/World-ski_2.obf.zip ${WORK_DIR}osmand_data/World-ski_2.obf 

echo $(date)' Osmand Export complete'
exit 0

