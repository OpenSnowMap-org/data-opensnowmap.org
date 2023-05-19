#!/usr/bin/python3

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

tilesZ18 = []
zoom = 18

for Id in nodes_ids:
    cur.execute(" select distinct \
    st_x(st_transform(way,4326)), st_y(st_transform(way,4326)) \
    from planet_osm_point where osm_id=%s;"% (Id,))
    for c in cur.fetchall():
        x, y= deg2num(c[1],c[0],zoom)
        if [x,y] not in tilesZ18: tilesZ18.append([x,y])


"""Note:
At Z18, 1 pixel = 0.596m
1 tile = 256px = 152m
http://www.openstreetmap.org/way/142043938 > 4.4km, 2 noeuds

select distinct st_x(dp), st_y(dp)
    from (
        select (st_dumppoints(st_transform(way2,4326))).geom as dp 
            from (
                select ST_Segmentize(way,152) as way2
                from planet_osm_line
                where osm_id=142043938
            ) as foo 
        )as bar;
=> 45 noeuds
"""
for Id in ways_ids:
    cur.execute(" select distinct st_x(dp), st_y(dp)\
    from (\
        select (st_dumppoints(st_transform(way2,4326))).geom as dp \
            from (\
                select ST_Segmentize(way,152) as way2\
                from planet_osm_line\
                where osm_id=%s\
            ) as foo \
        )as bar;"% (Id,))
    for c in cur.fetchall():
        x, y= deg2num(c[1],c[0],zoom)
        if [x,y] not in tilesZ18: tilesZ18.append([x,y])

for Id in relations_ids:
    cur.execute(" select distinct st_x(dp), st_y(dp)\
    from (\
        select (st_dumppoints(st_transform(way2,4326))).geom as dp \
            from (\
                select ST_Segmentize(way,152) as way2\
                from planet_osm_line\
                where osm_id=-%s\
            ) as foo \
        )as bar;"% (Id,))
    for c in cur.fetchall():
        x, y= deg2num(c[1],c[0],zoom)
        if [x,y] not in tilesZ18: tilesZ18.append([x,y])

for Id in ways_ids:
    cur.execute(" select distinct st_x(dp), st_y(dp)\
    from (\
        select (st_dumppoints(st_transform(way2,4326))).geom as dp \
            from (\
                select ST_Segmentize(way,152) as way2\
                from planet_osm_polygon\
                where osm_id=%s\
            ) as foo \
        )as bar;"% (Id,))
    for c in cur.fetchall():
        x, y= deg2num(c[1],c[0],zoom)
        if [x,y] not in tilesZ18: tilesZ18.append([x,y])

for Id in relations_ids:
    cur.execute(" select distinct st_x(dp), st_y(dp)\
    from (\
        select (st_dumppoints(st_transform(way2,4326))).geom as dp \
            from (\
                select ST_Segmentize(way,152) as way2\
                from planet_osm_polygon\
                where osm_id=-%s\
            ) as foo \
        )as bar;"% (Id,))
    for c in cur.fetchall():
        x, y= deg2num(c[1],c[0],zoom)
        if [x,y] not in tilesZ18: tilesZ18.append([x,y])

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
        x, y= deg2num(c[1],c[0],zoom)
        if [x,y] not in tilesZ18: tilesZ18.append([x,y])


"""Note:
At Z18, 1 pixel = 0.596m
1 tile = 256px = 152m
http://www.openstreetmap.org/way/142043938 > 4.4km, 2 noeuds

select distinct st_x(dp), st_y(dp)
    from (
        select (st_dumppoints(st_transform(way2,4326))).geom as dp 
            from (
                select ST_Segmentize(way,152) as way2
                from planet_osm_line
                where osm_id=142043938
            ) as foo 
        )as bar;
=> 45 noeuds
"""
for Id in ways_ids:
    cur.execute(" select distinct st_x(dp), st_y(dp)\
    from (\
        select (st_dumppoints(st_transform(way2,4326))).geom as dp \
            from (\
                select ST_Segmentize(way,152) as way2\
                from planet_osm_line\
                where osm_id=%s\
            ) as foo \
        )as bar;"% (Id,))
    for c in cur.fetchall():
        x, y= deg2num(c[1],c[0],zoom)
        if [x,y] not in tilesZ18: tilesZ18.append([x,y])

for Id in relations_ids:
    cur.execute(" select distinct st_x(dp), st_y(dp)\
    from (\
        select (st_dumppoints(st_transform(way2,4326))).geom as dp \
            from (\
                select ST_Segmentize(way,152) as way2\
                from planet_osm_line\
                where osm_id=-%s\
            ) as foo \
        )as bar;"% (Id,))
    for c in cur.fetchall():
        x, y= deg2num(c[1],c[0],zoom)
        if [x,y] not in tilesZ18: tilesZ18.append([x,y])

for Id in ways_ids:
    cur.execute(" select distinct st_x(dp), st_y(dp)\
    from (\
        select (st_dumppoints(st_transform(way2,4326))).geom as dp \
            from (\
                select ST_Segmentize(way,152) as way2\
                from planet_osm_polygon\
                where osm_id=%s\
            ) as foo \
        )as bar;"% (Id,))
    for c in cur.fetchall():
        x, y= deg2num(c[1],c[0],zoom)
        if [x,y] not in tilesZ18: tilesZ18.append([x,y])

for Id in relations_ids:
    cur.execute(" select distinct st_x(dp), st_y(dp)\
    from (\
        select (st_dumppoints(st_transform(way2,4326))).geom as dp \
            from (\
                select ST_Segmentize(way,152) as way2\
                from planet_osm_polygon\
                where osm_id=-%s\
            ) as foo \
        )as bar;"% (Id,))
    for c in cur.fetchall():
        x, y= deg2num(c[1],c[0],zoom)
        if [x,y] not in tilesZ18: tilesZ18.append([x,y])

conn.close()

tiles={}

for z in [18,17,16,15,14,13,12,11,10,9]:
    tiles[z]=[]
    for t in tilesZ18:
        tx=int(t[0]/2**(18-z))
        ty=int(t[1]/2**(18-z))
        if [tx,ty] not in tiles[z]: tiles[z].append([tx,ty])
    sys.stdout.write("z%s: %s tiles\n" % (z,len(tiles[z])))

f=open("/home/admin/Planet/data/expired_tiles.lst",'w')
for z in [18,17,16,15,14,13,12,11,10,9]:
    for t in tiles[z]:
        x=t[0]
        y=t[1]
        f.write(str(z)+'/'+str(x)+'/'+str(y)+'\n')
f.close()

f=open("/home/admin/Planet/data/expired.tsv",'w')
f.write("point\n")
for t in tiles[17]:
    x,y=num2deg(t[0],t[1],17)
    f.write(str(x)+','+str(y)+'\n')
f.close()

#~ cat expired_tiles.lst | render_expired --touch-from=0 --map=single --num-threads=1
