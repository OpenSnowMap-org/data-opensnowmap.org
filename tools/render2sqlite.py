#!/usr/bin/python
# create Osmand-compatible sqlite
import os
from mapnik import *
import math
import sqlite3

class SqliteTileStorage():
    """ Sqlite files methods for simple tile storage"""

    def __init__(self, type):
        self.type=type
    
    def create(self, filename, overwrite=False):
        """ Create a new storage file, overwrite or not if already exists"""
        self.filename=filename
        CREATEINDEX=True
        
        if overwrite:
            if os.path.isfile(self.filename):
                os.unlink(self.filename)
        else:
            if os.path.isfile(self.filename):
                CREATEINDEX=False
                
        self.db = sqlite3.connect(self.filename)
        
        cur = self.db.cursor()
        cur.execute(
            """
            CREATE TABLE IF NOT EXISTS tiles (
                x int,
                y int,
                z int, 
                s int,
                image blob,
                PRIMARY KEY(x,y,z,s))
            """)
        cur.execute(
            """
            CREATE TABLE IF NOT EXISTS info (
                desc TEXT,
                tilenumbering TEXT,
                minzoom int,
                maxzoom int)
            """)
        
        if CREATEINDEX:
            cur.execute(
                """
                CREATE INDEX IND
                ON tiles(x,y,z,s)
                """)
                
        cur.execute("insert into info(desc) values('Simple sqlite tile storage..')")
        
        cur.execute("insert into info(tilenumbering) values(?)",(self.type,))
        
        self.db.commit()
        
    def open(self, filename) :
        """ Open an existing file"""
        self.filename=filename
        if os.path.isfile(self.filename):
            self.db = sqlite3.connect(self.filename)
            return True
        else:
            return False
            
    def writeImageFile(self, x, y, z, f) :
        """ write a single tile from a file """
        cur = self.db.cursor()
        cur.execute('insert into tiles (z, x, y,s,image) \
                        values (?,?,?,?,?)',
                        (z, x, y, 0, sqlite3.Binary(f.read())))
        self.db.commit()
        
    def writeImage(self, x, y, z, image) :
        """ write a single tile from string """
        cur = self.db.cursor()
        cur.execute('insert into tiles (z, x, y,s,image) \
                        values (?,?,?,?,?)',
                        (z, x, y, 0, sqlite3.Binary(image)))
        
        
    def readImage(self, x, y, z) :
        """ read a single tile as string """
        
        cur = self.db.cursor()
        cur.execute("select image from tiles where x=? and y=? and z=?", (x, y, z))
        res = cur.fetchone()
        if res:
            image = str(res[0])
            return image
        else :
            return None
        
    def createFromDirectory(self, filename, basedir, overwrite=False) :
        """ Create a new sqlite file from a z/y/x.ext directory structure"""
        
        ls=os.listdir(basedir)
        
        self.create(filename, overwrite)
        cur = self.db.cursor()
        
        for zs in os.listdir(basedir):
            zz=int(zs)
            for xs in os.listdir(basedir+'/'+zs+'/'):
                xx=int(xs)
                for ys in os.listdir(basedir+'/'+zs+'/'+'/'+xs+'/'):
                    yy=int(ys.split('.')[0])
                    print zz, yy, xx
                    z=zz
                    x=xx
                    y=yy
                    print basedir+'/'+zs+'/'+'/'+xs+'/'+ys
                    f=open(basedir+'/'+zs+'/'+'/'+xs+'/'+ys)
                    cur.execute('insert into tiles (z, x, y,image) \
                                values (?,?,?,?)',
                                (z, x, y,  sqlite3.Binary(f.read())))
                                
    def createBigPlanetFromTMS(self, targetname, overwrite=False):
        """ Create a new sqlite with BigPlanet numbering scheme from a TMS one"""
        target=SqliteTileStorage('BigPlanet')
        target.create(targetname, overwrite)
        cur = self.db.cursor()
        cur.execute("select x, y, z from tiles")
        res = cur.fetchall()
        for (x, y, z) in res:
            xx= x
            zz= 17 - z
            yy= 2**z - y -1
            im=self.readImage(x,y,z)
            target.writeImage(xx,yy,zz,im)
        target.db.commit()
        
    def createTMSFromBigPlanet(self, targetname, overwrite=False):
        """ Create a new sqlite with TMS numbering scheme from a BigPlanet one"""
        target=SqliteTileStorage('TMS')
        target.create(targetname, overwrite)
        cur = self.db.cursor()
        cur.execute("select x, y, z from tiles")
        res = cur.fetchall()
        for (x, y, z) in res:
            xx= x
            zz= 17 - z
            yy= 2**zz - y -1
            im=self.readImage(x,y,z)
            target.writeImage(xx,yy,zz,im)
        target.db.commit()
    
    def createTMSFromOSM(self, targetname, overwrite=False):
        """ Create a new sqlite with TMS numbering scheme from a OSM/Bing/Googlemaps one"""
        target=SqliteTileStorage('TMS')
        target.create(targetname, overwrite)
        cur = self.db.cursor()
        cur.execute("select x, y, z from tiles")
        res = cur.fetchall()
        for (x, y, z) in res:
            xx= x
            zz= z
            yy= 2**zz - y -1
            im=self.readImage(x,y,z)
            target.writeImage(xx,yy,zz,im)
        target.db.commit()
    
    def createOSMFromTMS(self, targetname, overwrite=False):
        """ Create a new sqlite with OSM/Bing/Googlemaps numbering scheme from a TMS one"""
        target=SqliteTileStorage('OSM')
        target.create(targetname, overwrite)
        cur = self.db.cursor()
        cur.execute("select x, y, z from tiles")
        res = cur.fetchall()
        for (x, y, z) in res:
            xx= x
            zz= z
            yy= 2**zz - y -1
            im=self.readImage(x,y,z)
            target.writeImage(xx,yy,zz,im)
        target.db.commit()


def num2bbox(xtile, ytile, zoom):
	#from tilenames to bbox , see http://wiki.openstreetmap.org/wiki/Slippy_map_tilenames
	# to center the tiles:
	
	xtile= xtile 
	ytile= ytile
	n = 2.0 ** (zoom)
	lon1_deg = xtile / n * 360.0 - 180.0
	#ytile = (2**zoom-1) -ytile ##beware, TMS spec !
	lat1_rad = math.atan(math.sinh(math.pi * (1 - 2 * ytile / n)))
	lat1_deg = math.degrees(lat1_rad)
	
	xtile=xtile + 1
	ytile=ytile + 1
	lon2_deg = xtile / n * 360.0 - 180.0
	#ytile = (2**zoom-1) -ytile ##beware, TMS spec !
	lat2_rad = math.atan(math.sinh(math.pi * (1 - 2 * ytile / n)))
	lat2_deg = math.degrees(lat2_rad)
	# SW, NE
	return(lon1_deg, lat2_deg, lon2_deg, lat1_deg)

if len(sys.argv) <=2:
    print 'usage: ./tiles2osmandsqlite.py tilelist outputfile'
    exit()
infile=sys.argv[1]
outfile=sys.argv[2]

store=SqliteTileStorage('TMS')
store.create('/var/tmp/tmp.sqlitedb',True)
tiles=open(infile,'r').readlines()

# The size of the tile in pixel:
sx = 256
sy = 256
# Declare usefull projections
lonlat = Projection('+proj=longlat +datum=WGS84')

proj = "+proj=merc +a=6378137 +b=6378137 +lat_ts=0.0 +lon_0=0.0 +x_0=0.0 +y_0=0 +k=1.0 +units=m +nadgrids=@null +no_defs +over"

m = Map(sx,sy,proj)
mapfile="/home/website/mapnik/offset-style/map.xml"
load_map(m,mapfile)
m.background = Color("transparent")
cnt=0
for tile in tiles:
	print tile
	x=int(tile.split(' ')[0])
	y=int(tile.split(' ')[1])
	z=int(tile.split(' ')[2])
	
	
	# compute the bbox corresponding to the requested tile
	ll = num2bbox(x, y, z)
	#return str(ll)
	prj= Projection(proj)
	c0 = prj.forward(Coord(ll[0],ll[1]))
	c1 = prj.forward(Coord(ll[2],ll[3]))
	bbox = Envelope(c0.x,c0.y,c1.x,c1.y)
	
	bbox.width(bbox.width() )
	bbox.height(bbox.height() )
	
	# zoom the map to the bbox
	m.zoom_to_box(bbox)
	
	# render the tile
	im = Image(sx, sy)
	render(m, im)
	view = im.view(0, 0, sx, sy)
	y= 2**z - y -1
	store.writeImage(x,y,z,view.tostring('png'))
	cnt+=1
	if cnt == 100:
		store.db.commit()
		cnt=0
store.db.commit()
store.createBigPlanetFromTMS(outfile, True)
