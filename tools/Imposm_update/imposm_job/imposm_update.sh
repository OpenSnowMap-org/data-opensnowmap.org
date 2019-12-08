mkdir -p /home/admin/imposm_updates
home="/home/admin/imposm_updates"
log="/home/admin/imposm_updates/imposm_update.log"
log2="/home/admin/imposm_updates/imposm.log"

cd ${home}
if [ -f ${home}/lock ];
then
    echo "Sorry, process already running"
    exit 1
else
    
    touch ${home}/lock
    state=$(cat ${home}/state.txt)
    new_state=$(date -u +'%Y-%m-%dT%TZ' --date="5 minutes ago") # overlap
    echo "state: "$state
    echo "new_state: "$new_state
    echo $(date)" - Starting update from "$state" to "$new_state >> $log
    
    date
    echo "*******************************************"
    echo "Create diff file"
    echo "*******************************************"
    
    rm ${home}/change_file.osc.gz
    osmupdate $state ${home}/change_file.osc.gz
    
    if [ $? -ne 0 ]
    then
        echo $new_state >${home}/last_diff_file_downloaded.txt
    fi
    cd ${home}
    date
    echo "*******************************************"
    echo "Import: update DB"
    echo "*******************************************"
    # 5 days of diff = 14h
    imposm diff -mapping /home/admin/Imposm_job/opensnowmap.yml -quiet -cachedir "/home/admin/imposm_cache" -diffdir "/home/admin/imposm_cache" -connection postgis://imposm:imposm@localhost/imposm ${home}/change_file.osc.gz > $log2
    
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

    echo $new_state >${home}/state.txt
    rm ${home}/lock
#~ 
    echo "Done"
    echo $(date)" - Update done" >> $log
    date
fi
# Restart from 2016-06-28T19:00:00Z
