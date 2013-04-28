#!/usr/bin/python

import pdb
from lxml import etree
from StringIO import StringIO
import math
import argparse
import psycopg2


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
  
def parseXML(xmlFile):
    """
    Parse the xml
    """
    f = open(xmlFile)
    xml = f.read()
    f.close()
    coords=[]
    
    
    tree = etree.parse(StringIO(xml))
    
    context = etree.iterparse(StringIO(xml))
    for action, elem in context:
        if elem.tag == "node":
            lonlat={}
            lonlat['lon']=float(elem.get('lon'))
            lonlat['lat']=float(elem.get('lat'))
            coords.append(lonlat)
        elem.clear()
    return coords


def tile2meta(xtile,ytile):
    return None

parser = argparse.ArgumentParser()
# description='Create tile list from osm file'

parser.add_argument("-o", "--output", dest="ofilename",default="",
                  help="write tile list to file, default to stdout")
parser.add_argument("-z", "--min-zoom", dest="z",type=int,default=2,
                  help="minimum zoom level")
parser.add_argument("-Z", "--max-zoom", dest="Z",type=int,default=18,
                  help="maximum zoom level")
parser.add_argument("-j", "--geojson", dest="geojson",default="",
                  help="crop from a geojson polygon")
args = parser.parse_args()
print args

conn = psycopg2.connect("dbname=pistes-mapnik user=mapnik")
cur = conn.cursor()

json=False
if args.geojson != "" :
    json=open(args.geojson,'r').readline()
if args.ofilename:
    o=open(args.ofilename,'w')

cx,cy=num2deg(0.5, 0.5, args.Z+1)
cx2,cy2=num2deg(1.5, 1.5, args.Z+1)
dx=(cx2-cx)/3
dy=(cy2-cy)/3

for zoom in range(args.z,args.Z+1):
    print "zoom: ", str(zoom)
    if json:
        cur.execute("select distinct st_x(dp), st_y(dp)\
                from (\
                    select (st_dumppoints(mpts)).geom as dp \
                        from (\
                            select st_snaptogrid(st_segmentize(st_transform(way, 4326),%s),%s,%s,%s,%s) as mpts\
                            from planet_osm_line where \
                            st_intersects(way, st_transform(st_setsrid(ST_GeomFromGeoJSON('%s'),4326),900913))\
                        ) as foo \
                    )as bar;"% (dy/2,cx, cy, dx, dy,json))
    else:
        cur.execute("select distinct st_x(dp), st_y(dp)\
                from (\
                    select (st_dumppoints(mpts)).geom as dp \
                        from (\
                            select st_snaptogrid(st_segmentize(st_transform(way, 4326),%s),%s,%s,%s,%s) as mpts\
                            from planet_osm_line\
                        ) as foo \
                    )as bar;"% (dy/2,cx, cy, dx, dy))
    for c in cur.fetchall():
        x, y= deg2num(c[1],c[0],zoom)
        z = zoom
        if args.ofilename:
            o.write(str(x)+" "+str(y)+" "+str(z)+"\n")
        else:
            print str(str(x)+" "+str(y)+" "+str(z))
 


#~ cat tiles.lst | sort | uniq > uniq.lst
