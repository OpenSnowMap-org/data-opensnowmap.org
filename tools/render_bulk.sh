#!/bin/bash

#~ mkdir -p bulk_tiles
#~ split -l 100 all_metatiles_render_9-16.lst bulk_tiles/
today=$(date --date="today" +%Y-%m-%d)
/home/admin/Planet/tools/./list_all_metatiles.py /home/admin/Planet/data/planet_pistes.osm 15 16
mkdir -p bulk_tiles
rm bulk_tiles/*
split -l 100 all_metatiles_render_16-17.lst bulk_tiles/

function renderd_active() {
   STATUS=`systemctl is-active renderd.service`
   if [[ ${STATUS} == 'active' ]]; then
      true;
   else
      false;
   fi
   sleep 2
   return $?;
}

for f in bulk_tiles/*
do
    
    while ! renderd_active ; do
        echo "Waiting for renderd ..."
        sleep 1800
    done
        echo "Processing $f"
    cat $f | render_list --min-zoom 16 --num-threads=2 -f -m pistes-high-dpi
    cat $f | render_list --min-zoom 16 --num-threads=2 -f -m pistes
done

