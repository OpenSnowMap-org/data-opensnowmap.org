#!/usr/bin/env python


import pdb
import psycopg2
import os, sys
import urllib2
from lxml import etree
import json
import codecs
import pycountry

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
		resorts[osm_id]['name']=s[1].decode('utf8')
		resorts[osm_id]['lon']=s[2]
		resorts[osm_id]['lat']=s[3]

for r in resorts:
	try:
		nom_url="http://nominatim.openstreetmap.org/reverse?lat="+str(resorts[r]['lat'])+"&lon="+str(resorts[r]['lon'])+"&&accept-language=en"
	except: print resorts[r]
	nom=urllib2.urlopen(nom_url)
	nom_page=etree.parse(nom)
	root3=nom_page.getroot()
	code=root3.find('.//country_code').text
	resorts[r]['country']=pycountry.countries.get(alpha2=code.upper()).name
	try: resorts[r]['state']=root3.find('.//state').text
	except: resorts[r]['state']=''

print json.dumps(resorts, sort_keys=True, indent=4, ensure_ascii=False, encoding='utf8').encode('utf8')



