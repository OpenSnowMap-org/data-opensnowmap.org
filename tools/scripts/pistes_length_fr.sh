downhillmeter=$(echo "select sum(st_length_spheroid(st_transform(way,4326),'SPHEROID[\"WGS 84\",6378137,298.257223563]')) 
	from planet_osm_line where \"piste:type\"='downhill';" | psql -d pistes-mapnik -t)
nordicmeter=$(echo "select sum(st_length_spheroid(st_transform(way,4326),'SPHEROID[\"WGS 84\",6378137,298.257223563]')) 
	from planet_osm_line where \"piste:type\"='nordic' and  osm_id > 0;" | psql -d pistes-mapnik -t)
aerialwaymeter=$(echo "select sum(st_length_spheroid(st_transform(way,4326),'SPHEROID[\"WGS 84\",6378137,298.257223563]')) 
	from planet_osm_line where \"aerialway\" is not null and  osm_id > 0;" | psql -d pistes-mapnik -t)
hikemeter=$(echo "select sum(st_length_spheroid(st_transform(way,4326),'SPHEROID[\"WGS 84\",6378137,298.257223563]')) 
	from planet_osm_line where \"piste:type\"='hike' and  osm_id > 0;" | psql -d pistes-mapnik -t)
skitourmeter=$(echo "select sum(st_length_spheroid(st_transform(way,4326),'SPHEROID[\"WGS 84\",6378137,298.257223563]')) 
	from planet_osm_line where \"piste:type\"='skitour' and  osm_id > 0;" | psql -d pistes-mapnik -t)
downhill=$(echo "$downhillmeter / 1000" | bc)
nordic=$(echo "$nordicmeter / 1000" | bc)
aerialway=$(echo "$aerialwaymeter / 1000" | bc)
hike=$(echo "$hikemeter / 1000" | bc)
skitour=$(echo "$skitourmeter / 1000" | bc)

echo descente: $downhill km
echo ski de fond: $nordic km
echo remontées mécaniques: $aerialway km
echo rando: $skitour km
echo raquettes: $hike km

