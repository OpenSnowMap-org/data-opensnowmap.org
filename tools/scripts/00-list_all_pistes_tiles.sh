if  [ -d "/home/admin/" ]; then
	H=/home/admin/
else
	H=/home/website/
fi
WORK_DIR=${H}Planet/

osmosis=${H}"src/osmosis/bin/osmosis -q"

cd ${WORK_DIR}
# This script log
LOGFILE=${WORK_DIR}log/planet_update.log
# Directory where the planet file is stored
PLANET_DIR=${WORK_DIR}data/
TMP_DIR=${WORK_DIR}tmp/
TOOLS_DIR=${WORK_DIR}tools/

today=$(date --date="today" +%Y-%m-%d)

echo $(date)' List tiles '>> $LOGFILE
echo $(date)' List tiles '
pwd
${TOOLS_DIR}./list_all_metatiles.py ${PLANET_DIR}planet_pistes.osm 16
#~ ${TOOLS_DIR}./tile-list-from-db.py  -o all_tiles-$today.tilelist -z 0 -Z 18
#~ cat all_tiles-$today.tilelist | sort | uniq > uniq-$today.lst
#~ cat all_tiles-2014-01-08.lst | sort | uniq > uniq.lst
#~ cat uniq.lst | render_list --num-threads=6 -s /var/run/renderd/renderd.sock -m single -f
#~ if [ $? -ne 0 ]
#~ then
    #~ echo $(date)' FAILED Render tiles'>> $LOGFILE
    #~ exit 4
#~ else echo $(date)' Render tiles succeed '>> $LOGFILE
#~ fi

#~ cat uniq.lst | render_list -s /var/run/renderd/renderd.sock -m single
#~ if [ $? -ne 0 ]
#~ then
    #~ echo $(date)' FAILED Render tiles'>> $LOGFILE
    #~ exit 4
#~ else echo $(date)' Render tiles succeed '>> $LOGFILE
#~ fi
