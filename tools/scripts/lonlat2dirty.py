#!/usr/bin/env python
import math
import os, sys
import time
import datetime
import pdb

METATILE = 8
tile_path = "/var/lib/mod_tile"

def xyz_to_meta(xmlname, x,y, z):
    mask = METATILE -1
    x &= ~mask
    y &= ~mask
    hashes = {}

    for i in range(0,5):
        hashes[i] = ((x & 0x0f) << 4) | (y & 0x0f)
        x >>= 4
        y >>= 4

    meta = "%s/%s/%d/%u/%u/%u/%u/%u.meta" % (tile_path, xmlname, z, hashes[4], hashes[3], hashes[2], hashes[1], hashes[0])
    return meta

def deg2num(lat_deg, lon_deg, zoom):
  lat_rad = math.radians(lat_deg)
  n = 2.0 ** zoom
  xtile = int((lon_deg + 180.0) / 360.0 * n)
  ytile = int((1.0 - math.log(math.tan(lat_rad) + (1 / math.cos(lat_rad))) / math.pi) / 2.0 * n)
  return (xtile, ytile)

if len(sys.argv) < 4:
    print("usage: lonlat2dirty.py lon lat zoom style delete")
    exit(0)
print(sys.argv)


lon=float(sys.argv[1])
lat=float(sys.argv[2])
zoom=int(sys.argv[3])
style=str(sys.argv[4])
delete = False
if len(sys.argv) >= 6:
    if sys.argv[5] == "delete":
        delete = True


year = 2000
month = 1
day = 1
hour = 0
minute = 0
second = 0

z=zoom
print(z)

while z < 19:
    (x,y) = deg2num(lat, lon, z)
    print('\n')
    print(z,x,y)
    
    print(-2**(z-zoom),2**(z-zoom))
    print(x-2**(z-zoom),x+2**(z-zoom))
    print(y-2**(z-zoom),y+2**(z-zoom))
    for xx in range(x-2**(z-zoom),x+2**(z-zoom),1):
        for yy in range(y-2**(z-zoom),y+2**(z-zoom),1):
            
            fileLocation=xyz_to_meta(style,xx,yy,z)
            date = datetime.datetime(year=year, month=month, day=day, hour=hour, minute=minute, second=second)
            modTime = time.mktime(date.timetuple())
            if os.path.isfile(fileLocation):
                if delete:
                    os.remove(fileLocation)
                else:
                    os.utime(fileLocation, (modTime, modTime))
                print("found",xx,yy,z, fileLocation)
            else:
                pass #print("not found",x,y,z, fileLocation)
    z+=1
    
    
