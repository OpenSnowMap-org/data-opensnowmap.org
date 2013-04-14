#!/usr/bin/python

import pdb
from lxml import etree
from StringIO import StringIO
import math
import argparse

def deg2num(lat_deg, lon_deg, zoom):
  lat_rad = math.radians(lat_deg)
  n = 2.0 ** zoom
  xtile = int((lon_deg + 180.0) / 360.0 * n)
  ytile = int((1.0 - math.log(math.tan(lat_rad) + (1 / math.cos(lat_rad))) / math.pi) / 2.0 * n)
  return (xtile, ytile)
  
def deg2metanum(lat_deg, lon_deg, zoom, metatile):
  lat_rad = math.radians(lat_deg)
  n = 2.0 ** zoom
  xtile = int((lon_deg + 180.0) / 360.0 * n)
  ytile = int((1.0 - math.log(math.tan(lat_rad) + (1 / math.cos(lat_rad))) / math.pi) / 2.0 * n)
  xtile = xtile / metatile * metatile
  ytile = ytile / metatile * metatile
  return (xtile, ytile)
  
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
parser.add_argument("-f", "--file", dest="filename",
                  help="osm file to read")
parser.add_argument("-z", "--min-zoom", dest="z",type=int,default=0,
                  help="minimum zoom level")
parser.add_argument("-Z", "--max-zoom", dest="Z",type=int,default=18,
                  help="maximum zoom level")
parser.add_argument("-m", "--metatile", dest="metatile",
                  default=1,type=int,
                  help="metatile size, default to 1")
args = parser.parse_args()
print args

coords=parseXML(args.filename)
print "nodes: ", len(coords)
if args.ofilename:
    o=open(args.ofilename,'w')
for zoom in range(args.z,args.Z+1):
    print "zoom: ", str(zoom)
    for c in coords:
        x, y= deg2metanum(c['lat'],c['lon'],zoom,args.metatile)
        z = zoom
        if args.ofilename:
            o.write(str(x)+" "+str(y)+" "+str(z)+"\n")
        else:
            print str(str(x)+" "+str(y)+" "+str(z))
print "Tile list built"  


#~ cat tiles.lst | sort | uniq > uniq.lst
