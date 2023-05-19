mkdir -p /home/admin/imposm_updates
home="/home/admin/imposm_updates"
tool_dir="/home/admin/Imposm_job"
log="/home/admin/imposm_updates/imposm_update.log"
log2="/home/admin/imposm_updates/imposm.log"
readonly mappingfile=/home/admin/Planet/tools/Imposm_update/imposm_job/base_snowmap.yml
cd ${home}
if [ -f ${home}/lock ];
then
    echo "Sorry, process already running"
    echo $(date)" - Sorry, process already running" >> $log
    echo $(date)" - Sorry, process already running" >> $log2
    exit 1
else
    echo $(date)" - Starting update " >> $log2
    touch ${home}/lock
    sequenceId=$(cat ${home}/sequence.state)
    timestamp=$(${tool_dir}/getTimestampFromSequenceID.py $sequenceId https://planet.osm.org/replication/minute/)
    echo $(date)" - Starting update from "$timestamp", sequence "$sequenceId >> $log
    echo $(date)" - Starting update from "$timestamp", sequence "$sequenceId >> $log2
    
    date
    echo "*******************************************"
    echo "Create diff file"
    echo "*******************************************"
    
    rm ${home}/change_file.osc.gz
    pyosmium-get-changes -v -s 1024 --format osc.gz --server https://planet.osm.org/replication/minute/ -f ${home}/sequence.state -o ${home}/change_file.osc.gz >> $log2 2>&1 
    
    if [ $? -eq 0 ]
    then
        sequenceId=$(cat ${home}/sequence.state)
        timestamp=$(${tool_dir}/getTimestampFromSequenceID.py $sequenceId https://planet.osm.org/replication/minute/)
        echo $timestamp >${home}/last_diff_file_downloaded.txt
        echo $timestamp >${home}/state.txt

		cd ${home}
		date
		echo "*******************************************"
		echo "Import: update DB"
		echo "*******************************************"
		# 5 days of diff = 14h
		imposm diff -mapping $mappingfile -cachedir "/home/admin/imposm_cache" -diffdir "/home/admin/imposm_cache" -connection postgis://imposm:imposm@localhost/imposm ${home}/change_file.osc.gz >> $log2 2>&1 
		if [ $? -ne 0] 
		then 
			echo $(date)" - Imposm failure" >> $log
			echo $(date)" - Imposm failure" >> $log2
			exit 1
		fi
		#~ SECONDS=0
		#~ echo "REFRESH MATERIALIZED VIEW pistes_routes;" |psql -d imposm -U imposm
		#~ echo "ANALYSE pistes_routes;" |psql -d imposm -U imposm
		#~ duration=$SECONDS
		#~ echo "pistes_routes view refreshed in $(($duration / 60)) min $(($duration % 60))s."

		#~ SECONDS=0
		#~ echo "REFRESH MATERIALIZED VIEW pistes_sites;" |psql -d imposm -U imposm
		#~ echo "ANALYSE pistes_sites;" |psql -d imposm -U imposm
		#~ duration=$SECONDS
		#~ echo "pistes_sites view refreshed in $(($duration / 60)) min $(($duration % 60))s."

		
		rm ${home}/lock
		echo "Done"
		echo $(date)" - Update done" >> $log
		echo $(date)" - Update done" >> $log2
		date
    else 
		echo $(date)" - Issue in getting OSM change file, resuming " >> $log
		echo $(date)" - Issue in getting OSM change file, resuming " >> $log2
		#~ we can safely try again later when the server is available
		rm ${home}/lock
	fi
fi
# Restart from 2016-06-28T19:00:00Z
