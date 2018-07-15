home="/home/admin/SSD"
log="/home/admin/SSD/data/update.log"
log2="/home/admin/SSD/data/imposm.log"

cd ${home}
if [ -f ${home}/data/lock ];
then
    echo "Sorry, process already running"
    exit 1
else
    
    touch ${home}/data/lock
    state=$(cat ${home}/data/state.txt)
    new_state=$(date -u +'%Y-%m-%dT%TZ' --date="5 minutes ago") # overlap
    echo "state: "$state
    echo "new_state: "$new_state
    echo $(date)" - Starting update from "$state" to "$new_state >> $log
    
    date
    echo "*******************************************"
    echo "Create diff file"
    echo "*******************************************"
    
    rm ${home}/data/change_file.osc.gz
    cd ${home}/update/
    ./osmupdate $state ${home}/data/change_file.osc.gz
    
    
    if [ $? -ne 0 ]
    then
        echo $new_state >${home}/data/last_diff_file_downloaded.txt
    fi
    cd ${home}
    date
    echo "*******************************************"
    echo "Import: update DB"
    echo "*******************************************"
    # 5 days of diff = 14h
    # 6 days of diff =
    #~ cd ${home}/imposm3-0.2.0dev/
    cd /home/admin/src/go/bin/
    ./imposm3 diff -mapping mapping.json -quiet -cachedir "/home/admin/SSD/imposm_cache" -diffdir "/home/admin/SSD/imposm_cache" -connection postgis://imposm:imposm@localhost/imposm ${home}/data/change_file.osc.gz > $log2

    echo $new_state >${home}/data/state.txt
    rm ${home}/data/lock
#~ 
    echo "Done"
    echo $(date)" - Update done" >> $log
    date
fi
# Restart from 2016-06-28T19:00:00Z
