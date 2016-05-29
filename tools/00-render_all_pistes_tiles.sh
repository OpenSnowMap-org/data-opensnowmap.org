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

echo $(date)' Render tiles '>> $LOGFILE
echo $(date)' Render tiles '
pwd
${TOOLS_DIR}./tile-list-from-db.py  -o all_tiles-$today.tilelist -z 0 -Z 16
cat all_tiles-$today.tilelist | sort | uniq > uniq.lst
#~ cat all_tiles-2014-01-08.lst | sort | uniq > uniq.lst
# if you don't erase the directory, then use -f option
cat uniq.lst | render_list --num-threads=6 -s /var/run/renderd/renderd.sock -m single
if [ $? -ne 0 ]
then
    echo $(date)' FAILED Render tiles'>> $LOGFILE
    exit 4
else echo $(date)' Render tiles succeed '>> $LOGFILE
fi

#~ cat uniq.lst | render_list -s /var/run/renderd/renderd.sock -m single
#~ if [ $? -ne 0 ]
#~ then
    #~ echo $(date)' FAILED Render tiles'>> $LOGFILE
    #~ exit 4
#~ else echo $(date)' Render tiles succeed '>> $LOGFILE
#~ fi
