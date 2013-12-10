#!/usr/bin/env python


import pdb
import psycopg2
import os, sys
from lxml import etree

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


conn = psycopg2.connect("dbname=pistes-mapnik-tmp user=mapnik")
cur = conn.cursor()
    
try: 
	cur.execute("ALTER TABLE planet_osm_point ADD site_name text;")
	conn.commit()
except:
	conn.rollback()
try: 
	cur.execute("ALTER TABLE planet_osm_point ADD entrance text;")
	conn.commit()
except:
	conn.rollback()
	
WORK_DIR=''
osmDoc=etree.parse(WORK_DIR+"/home/website/Planet/data/planet_pistes_sites.osm")

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
				cur.execute("INSERT INTO planet_osm_point(osm_id,site_name, \"piste:type\", way) VALUES(%s,%s, %s, ST_GeomFromText(%s,900913));",(idx,name, types_list, point))
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
							cur.execute("INSERT INTO planet_osm_point(osm_id,entrance, site_name, \"piste:type\", way) VALUES(%s, %s, %s, %s,  ST_SetSRID(ST_MakePoint(%s,%s),900913));",\
							(entrance,'yes',name, types_list, str(lonlat[0]),str(lonlat[1])))
						except:
							"""Traceback (most recent call last):
							  File "/home/website/Planet/tools/./make_sites.py", line 83, in <module>
							    (entrance,'yes',name, types_list, str(lonlat[0]),str(lonlat[1])))
							TypeError: 'NoneType' object has no attribute '__getitem__'"""
							pass
					conn.commit()
				
