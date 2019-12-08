#!/usr/bin/env python


import pdb
import psycopg2
import os, sys
from lxml import etree
import datetime
from cgi import escape

HOME_DIR=sys.argv[1]

def process(relation):
	name = ''
	tags= relation.findall('tag')
	for tag in tags:
		if tag.get('k')=='name':
			name=tag.get('v')
	members=relation.findall('member')
	ids=[]
	entrances=[]
	for member in members:
		if member.get('type') == 'relation':
			ids.append('-'+member.get('ref'))
		else:
			ids.append(member.get('ref'))
		
		if member.get('role') == 'entrance':
			entrances.append(member.get('ref'))
	id_list= ",".join(ids)
	entrances_list= ",".join(entrances)
	return name, id_list, entrances

print "makes_sites.py, process relations and landuses for ressorts rendering\n"
conn = psycopg2.connect("dbname=pistes-mapnik-tmp user=mapnik")
cur = conn.cursor()
    
try: 
	cur.execute("ALTER TABLE planet_osm_point ADD site_name text;")
	cur.execute("ALTER TABLE planet_osm_point ADD landuse text;")
	conn.commit()
except:
	conn.rollback()
try: 
	cur.execute("ALTER TABLE planet_osm_point ADD entrance text;")
	conn.commit()
except:
	conn.rollback()
	
osmDoc=etree.parse(HOME_DIR+"data/planet_pistes_sites.osm")

relations=osmDoc.findall('relation')

for relation in relations:
	tags= relation.findall('tag')
	for tag in tags:
		if tag.get('v')=='site':
			idx='-'+relation.get('id')
			name, id_list, entrances_list = process(relation)
			if id_list:
				cur.execute("select st_astext(st_centroid(st_collect(way))) from planet_osm_line where osm_id IN ("+id_list+");")
				point=cur.fetchone()[0]
				#print name, point
				cur.execute("select distinct \"piste:type\" from planet_osm_line where osm_id IN ("+id_list+");")
				types=cur.fetchall()
				
				types_list=[]
				for t in types:
					if t[0]!= None: types_list.append(t[0])
				
				types=sorted(types_list)
				#print types
				types_list=";".join(types)
				#print types_list
				cur.execute("INSERT INTO planet_osm_point(osm_id,site_name, \"piste:type\", way) VALUES(%s,%s, %s, ST_GeomFromText(%s,3857));",(idx,name, types_list, point))
				conn.commit()
				
				for entrance in entrances_list:
					cur.execute("select lon, lat from planet_osm_nodes where id = "+entrance+";")
					lonlat=cur.fetchone()
					cur.execute("select count(*) from planet_osm_point where osm_id = "+entrance+";")
					count=cur.fetchone()[0]
					if count != 0:
						cur.execute("UPDATE planet_osm_point SET entrance=%s, site_name=%s, \"piste:type\"=%s where osm_id= %s;",\
						('yes',name, types_list, entrance))
					else :
						try: 
							cur.execute("INSERT INTO planet_osm_point(osm_id,entrance, site_name, \"piste:type\", way) VALUES(%s, %s, %s, %s,  ST_SetSRID(ST_MakePoint(%s,%s),3857));",\
							(entrance,'yes',name, types_list, str(lonlat[0]),str(lonlat[1])))
						except:
							"""Traceback (most recent call last):
							  File "/home/admin/Planet/tools/./make_sites.py", line 83, in <module>
							    (entrance,'yes',name, types_list, str(lonlat[0]),str(lonlat[1])))
							TypeError: 'NoneType' object has no attribute '__getitem__'"""
							pass
					conn.commit()
cur.execute("""
			SELECT DISTINCT planet_osm_polygon.osm_id
				FROM planet_osm_polygon
				WHERE
				planet_osm_polygon.landuse = 'winter_sports' 
				AND 
				(planet_osm_polygon.name is not null OR planet_osm_polygon."piste:name" is not null)
				AND
				(
					SELECT count(planet_osm_line.*) FROM planet_osm_polygon, planet_osm_line
					WHERE
					planet_osm_polygon.landuse = 'winter_sports' 
					AND 
					(planet_osm_polygon.name is not null OR planet_osm_polygon."piste:name" is not null)
					AND 
					ST_Intersects(planet_osm_line.way,planet_osm_polygon.way)
				) > 3
			;
			""")
sites_ids=cur.fetchall()
ids=[str(long(x[0])) for x in sites_ids]
print "	Number of ways to process: ",len(ids)
l=len(ids)
for i in ids:
	l-=1
	#~ print l
	cur.execute("""
		INSERT INTO planet_osm_point(osm_id, "piste:type",site_name, way, landuse) 
		SELECT planet_osm_polygon.osm_id,string_agg(distinct planet_osm_line."piste:type",';'),
		 coalesce(planet_osm_polygon.name),st_centroid(planet_osm_polygon.way),
		 'winter_sports'
		FROM planet_osm_line, planet_osm_polygon
		WHERE 
		planet_osm_polygon.osm_id=%s
		AND
		ST_Intersects(planet_osm_line.way,
		planet_osm_polygon.way)
		AND
		(planet_osm_line."piste:type" in ('downhill',
			'hike',
			'ice-skate',
			'jump',
			'nordic',
			'playground',
			'skitour',
			'ski_jump',
			'sled',
			'sleigh',
			'snow_park')
			OR
			planet_osm_line.aerialway is not null)
		GROUP BY
		planet_osm_polygon.osm_id,planet_osm_polygon.name,planet_osm_polygon.way;
		""",(i,))
conn.commit()
#~ 
#~ # make landuse-> site osc

f=open(HOME_DIR+'/data/landuse.osc','w')
f.write('<osmChange version="0.6" generator="Opensnowmap">\n')
l=len(ids)
for i in ids:
	l-=1
	
	cur.execute("""
	SELECT planet_osm_point.site_name, planet_osm_point."piste:type"
	FROM planet_osm_point
	WHERE
	osm_id = %s
	""" % (i,))
	req=cur.fetchall()
	try :
		name=req[0][0]
		typ=req[0][1]
		cur.execute("""
				SELECT DISTINCT planet_osm_line.osm_id
					FROM planet_osm_line, planet_osm_polygon
					WHERE
					planet_osm_polygon.osm_id = %s
					AND
					ST_Intersects(planet_osm_line.way,planet_osm_polygon.way)
				;
				"""% (i,))
		members=cur.fetchall()
		member_ids=[str(long(x[0])) for x in members]
		
		f.write('   <create>\n')
		f.write('       <relation id="'+i+'" changeset="1" version="1" timestamp="')
		f.write(datetime.datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%S"))
		f.write('">\n')
		
		for m in member_ids:
			f.write('           <member type="way" role="" ref="'+str(m)+'"/>\n')
		f.write('           <tag k="name" v="'+escape(name,quote=True)+'"/>\n')
		if typ:
			f.write('           <tag k="piste:type" v="'+typ+'"/>\n')
		f.write('           <tag k="landuse" v="winter_sports"/>\n')
		f.write('           <tag k="site" v="piste"/>\n')
		f.write('           <tag k="was_way" v="yes"/>\n')
		f.write('       </relation>\n')
		f.write('   </create>\n')
	except  Exception,e:
		pass
		#~ print "error for way ", i
		#~ print str(e)
		#~ print req
		
	
f.write('</osmChange>')
