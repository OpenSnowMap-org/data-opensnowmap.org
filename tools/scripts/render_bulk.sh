#!/bin/bash

#~ mkdir -p bulk_tiles
#~ split -l 100 all_metatiles_render_9-16.lst bulk_tiles/
today=$(date --date="today" +%Y-%m-%d)
#~ /home/admin/Planet/tools/scripts/./list_all_metatiles.py /home/admin/Planet/data/planet_pistes.osm 0 16
#~ mkdir -p /home/admin/Planet/bulk_tiles
#~ rm /home/admin/Planet/bulk_tiles/*
#~ split -l 100 all_metatiles_render_0-16.lst /home/admin/Planet/bulk_tiles/

function renderd_active() {
   STATUS=`systemctl is-active renderd.service`
   if [[ ${STATUS} == 'active' ]]; then
      sleep 2
      true;
   else
      sleep 2
      false;
   fi
   return $?;
}

#~ for f in /home/admin/Planet/bulk_tiles/*
#~ do
    
    #~ while ! renderd_active ; do
        #~ echo "Waiting for renderd ..."
        #~ sleep 5
    #~ done
    #~ echo "Processing $f, pistes_high_dpi"
    #~ cat $f | render_list -f --min-zoom 0 --num-threads=12 -f -m pistes-high-dpi
#~ done

for f in /home/admin/Planet/bulk_tiles/*
do
    
    while ! renderd_active ; do
        echo "Waiting for renderd ..."
        sleep 5
    done
    echo "Processing $f, pistes-relief"
    cat $f | render_list -f --min-zoom 0 --num-threads=12 -f -m pistes-relief
done

exit 0

for f in /home/admin/Planet/bulk_tiles/*
do
    
    while ! renderd_active ; do
        echo "Waiting for renderd ..."
        sleep 5
    done
    echo "Processing $f, base"
    cat $f | render_list -f --min-zoom 12 --num-threads=12 -f -m base_snow_map
done

for f in /home/admin/Planet/bulk_tiles/*
do
    
    while ! renderd_active ; do
        echo "Waiting for renderd ..."
        sleep 5
    done
    echo "Processing $f, base_high_dpi"
    cat $f | render_list -f --min-zoom 12 --num-threads=12 -f -m base_snow_map_high_dpi
done
