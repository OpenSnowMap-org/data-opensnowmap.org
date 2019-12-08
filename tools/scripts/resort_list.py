#!/usr/bin/env python


import pdb
import psycopg2
import os, sys
import json
import codecs

con = psycopg2.connect("dbname=pistes-pgsnapshot user=xapi")
cur = con.cursor()
cur.execute("""
SELECT id,
	tags->'name',
	ST_X(ST_Centroid(geom)),
	ST_Y(ST_Centroid(geom))
FROM relations 
WHERE (tags->'type' = 'site' or tags->'landuse' = 'winter_sports')
ORDER by tags->'name';
""")
sites = cur.fetchall()
con.commit()

resorts={}
for s in sites:
	if s[1] and s[2] and s[3]:
		osm_id=str(long(s[0]))
		resorts[osm_id]={}
		resorts[osm_id]['name']=s[1].decode('utf8').replace('/',' - ')
		resorts[osm_id]['lon']=s[2]
		resorts[osm_id]['lat']=s[3]

cur.execute("""
SELECT id,
	tags->'name',
	ST_X(ST_Centroid(geom)),
	ST_Y(ST_Centroid(geom))
FROM relations 
WHERE (tags->'type' = 'site' or tags->'landuse' = 'winter_sports')
ORDER by tags->'name';
""")
sites = cur.fetchall()
con.commit()

con.close()
con = psycopg2.connect("dbname=imposm user=imposm")
cur = con.cursor()

for r in resorts:
	cur.execute("""
	SELECT name FROM osm_admin 
	WHERE 
		admin_level=2
		AND 
		st_intersects(
		 geometry,
		 ST_Transform(ST_GeometryFromText(
         'SRID=4326;POINT("""+str(resorts[r]['lon'])+""" """+str(resorts[r]['lat'])+""")'
         ),3857)
		);
	""")
	country = cur.fetchall()[0][0]
	#~ print name.encode('utf8')
	con.commit()
	resorts[r]['country']=country.replace('/',' - ')
	
	cur.execute("""
	SELECT name FROM osm_admin 
	WHERE 
		admin_level=4
		AND 
		st_intersects(
		 geometry,
		 ST_Transform(ST_GeometryFromText(
         'SRID=4326;POINT("""+str(resorts[r]['lon'])+""" """+str(resorts[r]['lat'])+""")'
         ),3857)
		);
	""")
	resorts[r]['state']=''
	try:
		state = cur.fetchall()[0][0]
		resorts[r]['state']=state
	except: pass
	con.commit()

print json.dumps(resorts, sort_keys=True, indent=4, ensure_ascii=False, encoding='utf8').encode('utf8')



