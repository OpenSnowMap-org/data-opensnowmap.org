wget http://planet.openstreetmap.org/pbf/planet-latest.osm.pbf -O ../data/planet-latest.osm.pbf
./osmconvert ../data/planet-latest.osm.pbf -o=../data/planet.o5m
echo "DONE"

