downhillmeter=$(echo "select sum(st_length_spheroid(st_transform(way,4326),'SPHEROID[\"WGS 84\",6378137,298.257223563]')) 
	from planet_osm_line where \"piste:type\"='downhill' and  osm_id > 0 and member_of is null;" | psql -d pistes-mapnik -U mapnik -t)
	
nordicmeter=$(echo "select sum(st_length_spheroid(st_transform(way,4326),'SPHEROID[\"WGS 84\",6378137,298.257223563]')) 
	from planet_osm_line where \"piste:type\"='nordic' and  osm_id > 0 and member_of is null;" | psql -d pistes-mapnik -U mapnik -t)
    
aerialwaymeter=$(echo "select sum(st_length_spheroid(st_transform(way,4326),'SPHEROID[\"WGS 84\",6378137,298.257223563]')) 
	from planet_osm_line where \"aerialway\" in ('drag_lift', 'lift', 'cable_car', 'platter', 'j-bar', 'rope_tow', 'mixed_lift', 'gondola', 't-bar', 'chair_lift', 'magic_carpet') and  osm_id > 0 and member_of is null;" | psql -d pistes-mapnik -U mapnik -t)
	
sledmeter=$(echo "select sum(st_length_spheroid(st_transform(way,4326),'SPHEROID[\"WGS 84\",6378137,298.257223563]')) 
	from planet_osm_line where \"piste:type\"='sled' and  osm_id > 0 and member_of is null;" | psql -d pistes-mapnik -U mapnik -t)
	
hikemeter=$(echo "select sum(st_length_spheroid(st_transform(way,4326),'SPHEROID[\"WGS 84\",6378137,298.257223563]')) 
	from planet_osm_line where \"piste:type\"='hike' and  osm_id > 0 and member_of is null;" | psql -d pistes-mapnik -U mapnik -t)
	
skitourmeter=$(echo "select sum(st_length_spheroid(st_transform(way,4326),'SPHEROID[\"WGS 84\",6378137,298.257223563]')) 
	from planet_osm_line where \"piste:type\"='skitour' and  osm_id > 0 and member_of is null;" | psql -d pistes-mapnik -U mapnik -t)
    
Rdownhillmeter=$(echo "select sum(st_length_spheroid(st_transform(way,4326),'SPHEROID[\"WGS 84\",6378137,298.257223563]')) 
	from planet_osm_line where \"piste:type\"='downhill' and  osm_id < 0;" | psql -d pistes-mapnik -U mapnik -t)
	
Rnordicmeter=$(echo "select sum(st_length_spheroid(st_transform(way,4326),'SPHEROID[\"WGS 84\",6378137,298.257223563]')) 
	from planet_osm_line where \"piste:type\"='nordic' and  osm_id < 0;" | psql -d pistes-mapnik -U mapnik -t)
    
Raerialwaymeter=$(echo "select sum(st_length_spheroid(st_transform(way,4326),'SPHEROID[\"WGS 84\",6378137,298.257223563]')) 
	from planet_osm_line where \"aerialway\" in ('drag_lift', 'lift', 'cable_car', 'platter', 'j-bar', 'rope_tow', 'mixed_lift', 'gondola', 't-bar', 'chair_lift', 'magic_carpet') and  osm_id < 0;" | psql -d pistes-mapnik -U mapnik -t)
	
Rsledmeter=$(echo "select sum(st_length_spheroid(st_transform(way,4326),'SPHEROID[\"WGS 84\",6378137,298.257223563]')) 
	from planet_osm_line where \"piste:type\"='sled' and  osm_id < 0;" | psql -d pistes-mapnik -U mapnik -t)
	
Rhikemeter=$(echo "select sum(st_length_spheroid(st_transform(way,4326),'SPHEROID[\"WGS 84\",6378137,298.257223563]')) 
	from planet_osm_line where \"piste:type\"='hike' and  osm_id < 0;" | psql -d pistes-mapnik -U mapnik -t)
	
Rskitourmeter=$(echo "select sum(st_length_spheroid(st_transform(way,4326),'SPHEROID[\"WGS 84\",6378137,298.257223563]')) 
	from planet_osm_line where \"piste:type\"='skitour' and  osm_id < 0;" | psql -d pistes-mapnik -U mapnik -t)
downhill=$(     echo "($downhillmeter + $Rdownhillmeter) / 1000" | bc)
nordic=$(       echo "($nordicmeter + $Rnordicmeter) / 1000" | bc)
aerialway=$(    echo "($aerialwaymeter + $Raerialwaymeter) / 1000" | bc)
sled=$(         echo "($sledmeter + $Rsledmeter) / 1000" | bc)
hike=$(         echo "($hikemeter + $Rhikemeter) / 1000" | bc)
skitour=$(      echo "($skitourmeter + $Rskitourmeter) / 1000" | bc)
if  [ -d "/home/admin/" ]; then
	date=$(cat /home/admin/Planet/data/state.txt)
else
	date=$(cat /home/website/Planet/data/state.txt)
fi

echo {
echo \"downhill\": $downhill,
echo \"nordic\": $nordic,
echo \"aerialway\": $aerialway,
echo \"skitour\": $skitour,
echo \"sled\": $sled ,
echo \"snowshoeing\": $hike,
echo \"date\": \"$date\"
echo }

