#!/usr/bin/env python


import pdb
import psycopg2
import os, sys
from lxml import etree

conn = psycopg2.connect("dbname=pistes-mapnik user=mapnik")
cur = conn.cursor()
    
try: 
	cur.execute("ALTER TABLE planet_osm_line ADD member_of bigint[];")
	conn.commit()
except:
	conn.rollback()

cur.execute("select id, parts from planet_osm_rels;")
relations=cur.fetchall()

i=len(relations)

for relation in relations:
	relid=relation[0]
	for wayid in relation[1]:
		cur.execute("update planet_osm_line set member_of= (\
				select array_append(member_of::bigint[], %s::bigint)\
				from planet_osm_line where osm_id = %s limit 1) \
			where osm_id = %s;" % (relid, wayid, wayid))
	i-=1
	sys.stdout.write("%s \r" % (i) )
	sys.stdout.flush()
conn.commit()

cur.execute("update planet_osm_line set \"piste:grooming\"= 'classic;skating' \
			where \"piste:grooming\"= 'classic+skating';")
conn.commit()
