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

def meta_to_xyz(pattern_meta_with_zoom='6/0/0/0/50/136'):
    """
    Convert meta tiles to z x y scheme for mod_tile
    Author: Thomas Gratier based on Frederik Ramm C code from meta2tile.c from mod_tile
    License: GPL
    """
    x, y = 0, 0
    path_elements = [int(i) for i in pattern_meta_with_zoom.split('/')]
    z = path_elements.pop(0)
    for i in path_elements:
        x <<= 4
        y <<= 4
        x |= (i & 0xf0) >> 4
        y |= (i & 0x0f)
    return z, x, y
    
def xyz_to_meta(pattern_xyz='12/981/1535'):
    """
    Convert meta tiles to z x y scheme for mod_tile
    Author: Chad Nelson based on reverse operation of Thomas Gratier's meta_to_xyz
    License: GPL, LGPL, WTFPL
    """
    path_elements = pattern_xyz.split('/')
    path_elements = map(int, path_elements)
    z = path_elements[0]
    x = path_elements[1]
    y = path_elements[2]
    meta_path = list([z, 0, 0, 0, 0, 0])
    for i in range(5, 1, -1):
        meta_path[i] = ((x & 0x0f) << 4) | (y & 0x0f)
        x >>= 4
        y >>= 4
    return "".join(str(x)+'/' for x in meta_path).strip( '/' )


sys.stdout.write("Parsing planet file for ids...")
sys.stdout.flush()
filename = sys.argv[1]
minzoom = int(sys.argv[2])
maxzoom = int(sys.argv[3])


tree = etree.parse(filename)
root = tree.getroot()
ways_ids=[]
relations_ids=[]
nodes_ids=[]

# get Ids
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

#Get nodes lon lat from database
conn = psycopg2.connect("dbname=pistes-mapnik user=mapnik")
cur = conn.cursor()

"""Note:
At Z18, 1 pixel = 0.596m
1 tile = 256px = 152m
8 tiles = 1216m
http://www.openstreetmap.org/way/142043938 > 4.4km, 2 noeuds

select distinct st_x(dp), st_y(dp)
    from (
        select (st_dumppoints(st_transform(way2,4326))).geom as dp 
            from (
                select ST_Segmentize(way,1216) as way2
                from planet_osm_line
                where osm_id=142043938
            ) as foo 
        )as bar;
=> 45 noeuds

At zoom 16, 1 pixel = 2.387m
1 tile = 611m
8 tiles = 9728m
"""

tilesZmax = []
zoom = 16
sys.stdout.write("retrieving nodes coords ...")
sys.stdout.flush()
for Id in nodes_ids:
    cur.execute(" select distinct \
    st_x(st_transform(way,4326)), st_y(st_transform(way,4326)) \
    from planet_osm_point where osm_id=%s;"% (Id,))
    for c in cur.fetchall():
        tx, ty= deg2num(c[1],c[0],zoom)
        meta=xyz_to_meta(str(zoom)+'/'+str(tx)+'/'+str(ty))
        (z, tx, ty) = meta_to_xyz(meta)
        if [tx,ty] not in tilesZmax: tilesZmax.append([tx,ty])
#
#
#
sys.stdout.write("retrieving ways coords ...")
sys.stdout.flush()
for Id in ways_ids:
    cur.execute(" select distinct st_x(dp), st_y(dp)\
    from (\
        select (st_dumppoints(st_transform(way2,4326))).geom as dp \
            from (\
                select ST_Segmentize(way,1216) as way2\
                from planet_osm_line\
                where osm_id=%s\
            ) as foo \
        )as bar;"% (Id,))
    for c in cur.fetchall():
        tx, ty= deg2num(c[1],c[0],zoom)
        meta=xyz_to_meta(str(zoom)+'/'+str(tx)+'/'+str(ty))
        (z, tx, ty) = meta_to_xyz(meta)
        if [tx,ty] not in tilesZmax: tilesZmax.append([tx,ty])

sys.stdout.write("retrieving routes coords ...")
sys.stdout.flush()
for Id in relations_ids:
    cur.execute(" select distinct st_x(dp), st_y(dp)\
    from (\
        select (st_dumppoints(st_transform(way2,4326))).geom as dp \
            from (\
                select ST_Segmentize(way,1216) as way2\
                from planet_osm_line\
                where osm_id=-%s\
            ) as foo \
        )as bar;"% (Id,))
    for c in cur.fetchall():
        tx, ty= deg2num(c[1],c[0],zoom)
        meta=xyz_to_meta(str(zoom)+'/'+str(tx)+'/'+str(ty))
        (z, tx, ty) = meta_to_xyz(meta)
        if [tx,ty] not in tilesZmax: tilesZmax.append([tx,ty])

sys.stdout.write("retrieving loops coords ...")
sys.stdout.flush()
for Id in ways_ids:
    cur.execute(" select distinct st_x(dp), st_y(dp)\
    from (\
        select (st_dumppoints(st_transform(way2,4326))).geom as dp \
            from (\
                select ST_Segmentize(way,1216) as way2\
                from planet_osm_polygon\
                where osm_id=%s\
            ) as foo \
        )as bar;"% (Id,))
    for c in cur.fetchall():
        tx, ty= deg2num(c[1],c[0],zoom)
        meta=xyz_to_meta(str(zoom)+'/'+str(tx)+'/'+str(ty))
        (z, tx, ty) = meta_to_xyz(meta)
        if [tx,ty] not in tilesZmax: tilesZmax.append([tx,ty])

sys.stdout.write("retrieving area coords ...")
sys.stdout.flush()
for Id in relations_ids:
    cur.execute(" select distinct st_x(dp), st_y(dp)\
    from (\
        select (st_dumppoints(st_transform(way2,4326))).geom as dp \
            from (\
                select ST_Segmentize(way,1216) as way2\
                from planet_osm_polygon\
                where osm_id=-%s\
            ) as foo \
        )as bar;"% (Id,))
    for c in cur.fetchall():
        tx, ty= deg2num(c[1],c[0],zoom)
        meta=xyz_to_meta(str(zoom)+'/'+str(tx)+'/'+str(ty))
        (z, tx, ty) = meta_to_xyz(meta)
        if [tx,ty] not in tilesZmax: tilesZmax.append([tx,ty])

conn.close()

f=open("metatiles_expiry"+str(maxzoom)+".lst",'w')
for t in tilesZmax:
    x=t[0]
    y=t[1]
    f.write(str(x)+'/'+str(ty)+'/'+str(maxzoom)+'\n')
f.close()

tiles={}

for z in range(minzoom,maxzoom+1):
    if z not in tiles: tiles[z]=[]
    for t in tilesZmax:
        tx=int(t[0]/2**(18-z))
        ty=int(t[1]/2**(18-z))
        meta=xyz_to_meta(str(zoom)+'/'+str(tx)+'/'+str(ty))
        (tz, tx, ty) = meta_to_xyz(meta)
        if [tx,ty] not in tiles[z]: tiles[z].append([tx,ty])
    sys.stdout.write("Result z%s: %s tiles\n" % (z,len(tiles[z])))
    sys.stdout.flush()

f=open("all_metatiles_expiry_"+str(minzoom)+"-"+str(maxzoom)+".lst",'w')
for z in range(minzoom,maxzoom+1):
    for t in tiles[z]:
        x=t[0]
        y=t[1]
        f.write(str(x)+'/'+str(y)+'/'+str(z)+'\n')
f.close()

f=open("all_metatiles_render_"+str(minzoom)+"-"+str(maxzoom)+".lst",'w')
for z in range(minzoom,maxzoom+1):
    for t in tiles[z]:
        x=t[0]
        y=t[1]
        f.write(str(x)+' '+str(y)+' '+str(z)+'\n')
f.close()
#~ cat expired_tiles.lst | render_expired --touch-from=0 --map=single --num-threads=1
