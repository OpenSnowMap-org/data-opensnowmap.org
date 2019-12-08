wget http://planet.openstreetmap.org/pbf/planet-latest.osm.pbf -O /home/admin/Planet/data/planet-latest.osm.pbf
osmconvert ../data/planet-latest.osm.pbf -o=../data/planet.o5m
echo "DONE"

