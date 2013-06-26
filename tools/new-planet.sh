wget http://planet.openstreetmap.org/pbf/planet-latest.osm.pbf
./osmconvert planet-latest.osm.pbf --timestamp=2013-05-14T00\:00\:00Z -o=../data/planet.o5m
