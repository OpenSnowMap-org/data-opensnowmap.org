#!/bin/bash


cp $1 ../tmp/old.gz
cp $2 ../tmp/new.gz
gunzip -c ../tmp/old.gz > ../tmp/old.osm
gunzip -c ../tmp/new.gz > ../tmp/new.osm

./osmconvert ../tmp/old.osm ../tmp/new.osm --diff -o=../tmp/diff.osc

createdb -U mapnik -T pistes-mapnik-tmp expiry-old-tmp
createdb -U mapnik -T pistes-mapnik-tmp expiry-new-tmp
/usr/bin/osm2pgsql -U mapnik -s -c -m -d expiry-old-tmp -S ../config/pistes.style ../tmp/old.osm 
/usr/bin/osm2pgsql -U mapnik -s -c -m -d expiry-new-tmp -S ../config/pistes.style ../tmp/old.osm 
 
./list_expired.py ../tmp/diff.osc expiry-old-tmp expiry-new-tmp
cat expired_tiles.lst | /usr/local/bin/render_expired --map=base_snow_map --touch-from=0 --num-threads=1
cat expired_tiles.lst | /usr/local/bin/render_expired --map=base_snow_map_high_dpi --touch-from=0 --num-threads=1
cat expired_tiles.lst | /usr/local/bin/render_expired --map=pistes-relief --touch-from=0 --num-threads=1
cat expired_tiles.lst | /usr/local/bin/render_expired --map=pistes --touch-from=0 --num-threads=1
cat expired_tiles.lst | /usr/local/bin/render_expired --map=pistes-high-dpi --touch-from=0 --num-threads=1

dropdb expiry-old-tmp
dropdb expiry-new-tmp
