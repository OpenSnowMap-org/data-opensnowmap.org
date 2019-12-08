#!/usr/bin/python

import pdb
from lxml import etree
import sys
import psycopg2
import math

def deg2num(lat_deg, lon_deg, zoom):
  lat_rad = math.radians(lat_deg)
  n = 2.0 ** zoom
  xtile = int((lon_deg + 180.0) / 360.0 * n)
  ytile = int((1.0 - math.log(math.tan(lat_rad) + (1 / math.cos(lat_rad))) / math.pi) / 2.0 * n)
  return (xtile, ytile)

def num2deg(xtile, ytile, zoom):
  n = 2.0 ** zoom
  lon_deg = (xtile) / n * 360.0 - 180.0
  lat_rad = math.atan(math.sinh(math.pi * (1 - 2 * (ytile) / n)))
  lat_deg = math.degrees(lat_rad)
  return (lat_deg, lon_deg)
#~ Open and parse change file

sys.stdout.write("Parsing changefile for ids")
filename = sys.argv[1]
old_db = sys.argv[2]
new_db = sys.argv[3]

tree = etree.parse(filename)
root = tree.getroot()
ways_ids=[]
relations_ids=[]
nodes_ids=[]
for element in root.iter():
    ways = element.findall('way')
    if len(ways):
        for w in ways:
            ways_ids.append(w.get('id'))
            
    relations = element.findall('relation')
    if len(relations):
        for w in relations:
            relations_ids.append(w.get('id'))
            
    nodes = element.findall('node')
    if len(nodes):
        for w in nodes:
            nodes_ids.append(w.get('id'))
sys.stdout.write("nodes: %s, ways: %s, relations: %s \n" % (len(nodes_ids), len(ways_ids), len(relations_ids)))

#Get nodes lon lat from new database
conn = psycopg2.connect("dbname="+old_db+" user=mapnik")
cur = conn.cursor()

nodesList = []
zoom = 18

for Id in nodes_ids:
    cur.execute(" select distinct \
    st_x(st_transform(way,4326)), st_y(st_transform(way,4326)) \
    from planet_osm_point where osm_id=%s;"% (Id,))
    for c in cur.fetchall():
        x, y= (c[1],c[0])
        if [x,y] not in nodesList: nodesList.append([x,y])


"""Note:
At Z18, 1 pixel = 0.596m
1 tile = 256px = 152m
http://www.openstreetmap.org/way/142043938 > 4.4km, 2 noeuds

select distinct st_x(dp), st_y(dp)
    from (
        select (st_dumppoints(st_transform(way,4326))).geom as dp 
            from (
                select ST_Segmentize(way,152) as way
                from planet_osm_line
                where osm_id=142043938
            ) as foo 
        )as bar;
=> 45 noeuds
"""
for Id in ways_ids:
    cur.execute(" select distinct st_x(dp), st_y(dp)\
    from (\
        select (st_dumppoints(st_transform(way,4326))).geom as dp \
            from  planet_osm_line\
                where osm_id=%s\
        )as bar;"% (Id,))
    for c in cur.fetchall():
        x, y= (c[1],c[0])
        if [x,y] not in nodesList: nodesList.append([x,y])

for Id in relations_ids:
    cur.execute("select distinct st_x(dp), st_y(dp)\
    from (\
        select (st_dumppoints(st_transform(way,4326))).geom as dp \
            from  planet_osm_line\
                where osm_id=-%s\
        )as bar;"% (Id,))
    for c in cur.fetchall():
        x, y= (c[1],c[0])
        if [x,y] not in nodesList: nodesList.append([x,y])

for Id in ways_ids:
    cur.execute(" select distinct st_x(dp), st_y(dp)\
    from (\
        select (st_dumppoints(st_transform(way,4326))).geom as dp \
            from planet_osm_polygon\
                where osm_id=%s\
        )as bar;"% (Id,))
    for c in cur.fetchall():
        x, y= (c[1],c[0])
        if [x,y] not in nodesList: nodesList.append([x,y])

for Id in relations_ids:
    cur.execute(" select distinct st_x(dp), st_y(dp)\
    from (\
        select (st_dumppoints(st_transform(way,4326))).geom as dp \
            from planet_osm_polygon\
                where osm_id=-%s\
        )as bar;"% (Id,))
    for c in cur.fetchall():
        x, y= (c[1],c[0])
        if [x,y] not in nodesList: nodesList.append([x,y])

conn.close()

#Get nodes lon lat from old database (if pistes have been deleted)
conn = psycopg2.connect("dbname="+new_db+" user=mapnik")
cur = conn.cursor()

zoom = 18

for Id in nodes_ids:
    cur.execute(" select distinct \
    st_x(st_transform(way,4326)), st_y(st_transform(way,4326)) \
    from planet_osm_point where osm_id=%s;"% (Id,))
    for c in cur.fetchall():
        x, y= (c[1],c[0])
        if [x,y] not in nodesList: nodesList.append([x,y])


"""Note:
At Z18, 1 pixel = 0.596m
1 tile = 256px = 152m
http://www.openstreetmap.org/way/142043938 > 4.4km, 2 noeuds

select distinct st_x(dp), st_y(dp)
    from (
        select (st_dumppoints(st_transform(way,4326))).geom as dp 
            from (
                select ST_Segmentize(way,152) as way
                from planet_osm_line
                where osm_id=142043938
            ) as foo 
        )as bar;
=> 45 noeuds
"""
for Id in ways_ids:
    cur.execute(" select distinct st_x(dp), st_y(dp)\
    from (\
        select (st_dumppoints(st_transform(way,4326))).geom as dp \
            from planet_osm_line\
                where osm_id=%s\
        )as bar;"% (Id,))
    for c in cur.fetchall():
        x, y= (c[1],c[0])
        if [x,y] not in nodesList: nodesList.append([x,y])

for Id in relations_ids:
    cur.execute(" select distinct st_x(dp), st_y(dp)\
    from (\
        select (st_dumppoints(st_transform(way,4326))).geom as dp \
            from planet_osm_line\
                where osm_id=-%s\
        )as bar;"% (Id,))
    for c in cur.fetchall():
        x, y= (c[1],c[0])
        if [x,y] not in nodesList: nodesList.append([x,y])

for Id in ways_ids:
    cur.execute(" select distinct st_x(dp), st_y(dp)\
    from (\
        select (st_dumppoints(st_transform(way,4326))).geom as dp \
            from planet_osm_polygon\
                where osm_id=%s\
        )as bar;"% (Id,))
    for c in cur.fetchall():
        x, y= (c[1],c[0])
        if [x,y] not in nodesList: nodesList.append([x,y])

for Id in relations_ids:
    cur.execute(" select distinct st_x(dp), st_y(dp)\
    from (\
        select (st_dumppoints(st_transform(way,4326))).geom as dp \
            from planet_osm_polygon\
                where osm_id=-%s\
        )as bar;"% (Id,))
    for c in cur.fetchall():
        x, y= (c[1],c[0])
        if [x,y] not in nodesList: nodesList.append([x,y])

conn.close()

f=open("daily_complete_nodes.csv",'w')
f.write("point"+'\n')
for t in nodesList:
    f.write(str(t[0])+','+str(t[1])+'\n')
f.close()

