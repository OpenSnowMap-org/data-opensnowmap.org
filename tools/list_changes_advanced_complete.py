#!/usr/bin/python

import pdb
from lxml import etree
import sys
import psycopg2
import math
import os

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

filename = sys.argv[1]
new_db = sys.argv[2]
old_db = sys.argv[3]

if len(sys.argv) > 4:
    out_dir = sys.argv[4]
else :
    out_dir = ""
if len(sys.argv) > 5:
    prefix = sys.argv[5]
else :
    prefix = ""

#~ Create output files
Basename = out_dir+prefix+"_"
nodes_added_file=open(Basename+"nodes_added.csv",'w')
nodes_added_file.write("point"+'\n')
ways_added_file=open(Basename+"ways_added.csv",'w')
ways_added_file.write("point"+'\n')
relations_added_file=open(Basename+"relations_added.csv",'w')
relations_added_file.write("point"+'\n')

nodes_modified_file=open(Basename+"nodes_modified.csv",'w')
nodes_modified_file.write("point"+'\n')
ways_modified_file=open(Basename+"ways_modified.csv",'w')
ways_modified_file.write("point"+'\n')
relations_modified_file=open(Basename+"relations_modified.csv",'w')
relations_modified_file.write("point"+'\n')

nodes_deleted_file=open(Basename+"nodes_deleted.csv",'w')
nodes_deleted_file.write("point"+'\n')
ways_deleted_file=open(Basename+"ways_deleted.csv",'w')
ways_deleted_file.write("point"+'\n')
relations_deleted_file=open(Basename+"relations_deleted.csv",'w')
relations_deleted_file.write("point"+'\n')

#~ Open and parse change file
sys.stdout.write("Parsing changefile for ids")

added_ways_ids=[]
added_relations_ids=[]
added_nodes_ids=[]

modified_ways_ids=[]
modified_relations_ids=[]
modified_nodes_ids=[]

deleted_ways_ids=[]
deleted_relations_ids=[]
deleted_nodes_ids=[]

tree = etree.parse(filename)
root = tree.getroot()
for element in root.iter():
    #~ Find added elements
    added = element.findall('create')
    if len(added):
        for e in added:
            ways = e.findall('way')
            if len(ways):
                for w in ways:
                    added_ways_ids.append(w.get('id'))
                
            relations = e.findall('relation')
            if len(relations):
                for w in relations:
                    added_relations_ids.append(w.get('id'))
                    
            nodes = e.findall('node')
            if len(nodes):
                for w in nodes:
                    added_nodes_ids.append(w.get('id'))
    #~ Find modified elements
    modified = element.findall('modify')
    if len(modified):
        for e in modified:
            ways = e.findall('way')
            if len(ways):
                for w in ways:
                    modified_ways_ids.append(w.get('id'))
                    
            relations = e.findall('relation')
            if len(relations):
                for w in relations:
                    modified_relations_ids.append(w.get('id'))
                    
            nodes = e.findall('node')
            if len(nodes):
                for w in nodes:
                    modified_nodes_ids.append(w.get('id'))
    #~ Find deleted elements
    deleted = element.findall('delete')
    if len(deleted):
        for e in deleted:
            ways = e.findall('way')
            if len(ways):
                for w in ways:
                    deleted_ways_ids.append(w.get('id'))
                    
            relations = e.findall('relation')
            if len(relations):
                for w in relations:
                    deleted_relations_ids.append(w.get('id'))
                    
            nodes = e.findall('node')
            if len(nodes):
                for w in nodes:
                    deleted_nodes_ids.append(w.get('id'))
sys.stdout.write("Added nodes: %s, ways: %s, relations: %s \n" % (len(added_nodes_ids), len(added_ways_ids), len(added_relations_ids)))
sys.stdout.write("Modified nodes: %s, ways: %s, relations: %s \n" % (len(modified_nodes_ids), len(modified_ways_ids), len(modified_relations_ids)))
sys.stdout.write("Deleted nodes: %s, ways: %s, relations: %s \n" % (len(deleted_nodes_ids), len(deleted_ways_ids), len(deleted_relations_ids)))


added_ways_nodeList=[]
added_relations_nodeList=[]
added_nodes_nodeList=[]

modified_ways_nodeList=[]
modified_relations_nodeList=[]
modified_nodes_nodeList=[]

deleted_ways_nodeList=[]
deleted_relations_nodeList=[]
deleted_nodes_nodeList=[]

#########################################################
#Get nodes lon lat from new database, added and modified
#########################################################
conn = psycopg2.connect("dbname="+new_db+" user=mapnik")
cur = conn.cursor()

for Id in added_nodes_ids:
    cur.execute(" select distinct \
    st_x(st_transform(st_simplify(way,25),4326)), st_y(st_transform(st_simplify(way,25),4326)) \
    from planet_osm_point where osm_id=%s;"% (Id,))
    for c in cur.fetchall():
        x, y= (c[1],c[0])
        if [x,y,Id] not in added_nodes_nodeList: added_nodes_nodeList.append([x,y,Id])

for Id in added_ways_ids:
    cur.execute(" select distinct st_x(dp), st_y(dp)\
    from (\
        select (st_dumppoints(st_transform(st_simplify(way,25),4326))).geom as dp \
            from  planet_osm_line\
                where osm_id=%s\
        )as bar;"% (Id,))
    for c in cur.fetchall():
        x, y= (c[1],c[0])
        if [x,y,Id] not in added_ways_nodeList: added_ways_nodeList.append([x,y,Id])
    
    cur.execute(" select distinct st_x(dp), st_y(dp)\
    from (\
        select (st_dumppoints(st_transform(st_simplify(way,25),4326))).geom as dp \
            from planet_osm_polygon\
                where osm_id=%s\
        )as bar;"% (Id,))
    for c in cur.fetchall():
        x, y= (c[1],c[0])
        if [x,y,Id] not in added_ways_nodeList: added_ways_nodeList.append([x,y,Id])

for Id in added_relations_ids:
    cur.execute("select distinct st_x(dp), st_y(dp)\
    from (\
        select (st_dumppoints(st_transform(st_simplify(way,25),4326))).geom as dp \
            from  planet_osm_line\
                where osm_id=-%s\
        )as bar;"% (Id,))
    for c in cur.fetchall():
        x, y= (c[1],c[0])
        if [x,y,Id] not in added_relations_nodeList: added_relations_nodeList.append([x,y,Id])
    
    cur.execute(" select distinct st_x(dp), st_y(dp)\
    from (\
        select (st_dumppoints(st_transform(st_simplify(way,25),4326))).geom as dp \
            from planet_osm_polygon\
                where osm_id=-%s\
        )as bar;"% (Id,))
    for c in cur.fetchall():
        x, y= (c[1],c[0])
        if [x,y,Id] not in added_relations_nodeList: added_relations_nodeList.append([x,y,Id])

for Id in modified_nodes_ids:
    cur.execute(" select distinct \
    st_x(st_transform(st_simplify(way,25),4326)), st_y(st_transform(st_simplify(way,25),4326)) \
    from planet_osm_point where osm_id=%s;"% (Id,))
    for c in cur.fetchall():
        x, y= (c[1],c[0])
        if [x,y,Id] not in modified_nodes_nodeList: modified_nodes_nodeList.append([x,y,Id])

for Id in modified_ways_ids:
    cur.execute(" select distinct st_x(dp), st_y(dp)\
    from (\
        select (st_dumppoints(st_transform(st_simplify(way,25),4326))).geom as dp \
            from  planet_osm_line\
                where osm_id=%s\
        )as bar;"% (Id,))
    for c in cur.fetchall():
        x, y= (c[1],c[0])
        if [x,y,Id] not in modified_ways_nodeList: modified_ways_nodeList.append([x,y,Id])
    
    cur.execute(" select distinct st_x(dp), st_y(dp)\
    from (\
        select (st_dumppoints(st_transform(st_simplify(way,25),4326))).geom as dp \
            from planet_osm_polygon\
                where osm_id=%s\
        )as bar;"% (Id,))
    for c in cur.fetchall():
        x, y= (c[1],c[0])
        if [x,y,Id] not in modified_ways_nodeList: modified_ways_nodeList.append([x,y,Id])

for Id in modified_relations_ids:
    cur.execute("select distinct st_x(dp), st_y(dp)\
    from (\
        select (st_dumppoints(st_transform(st_simplify(way,25),4326))).geom as dp \
            from  planet_osm_line\
                where osm_id=-%s\
        )as bar;"% (Id,))
    for c in cur.fetchall():
        x, y= (c[1],c[0])
        if [x,y,Id] not in modified_relations_nodeList: modified_relations_nodeList.append([x,y,Id])
    
    cur.execute(" select distinct st_x(dp), st_y(dp)\
    from (\
        select (st_dumppoints(st_transform(st_simplify(way,25),4326))).geom as dp \
            from planet_osm_polygon\
                where osm_id=-%s\
        )as bar;"% (Id,))
    for c in cur.fetchall():
        x, y= (c[1],c[0])
        if [x,y,Id] not in modified_relations_nodeList: modified_relations_nodeList.append([x,y,Id])
conn.close()

#########################################################
#Get nodes lon lat from old database modified and deleted
#########################################################
conn = psycopg2.connect("dbname="+old_db+" user=mapnik")
cur = conn.cursor()
for Id in modified_nodes_ids:
    cur.execute(" select distinct \
    st_x(st_transform(st_simplify(way,25),4326)), st_y(st_transform(st_simplify(way,25),4326)) \
    from planet_osm_point where osm_id=%s;"% (Id,))
    for c in cur.fetchall():
        x, y= (c[1],c[0])
        if [x,y,Id] not in modified_nodes_nodeList: modified_nodes_nodeList.append([x,y,Id])

for Id in modified_ways_ids:
    cur.execute(" select distinct st_x(dp), st_y(dp)\
    from (\
        select (st_dumppoints(st_transform(st_simplify(way,25),4326))).geom as dp \
            from  planet_osm_line\
                where osm_id=%s\
        )as bar;"% (Id,))
    for c in cur.fetchall():
        x, y= (c[1],c[0])
        if [x,y,Id] not in modified_ways_nodeList: modified_ways_nodeList.append([x,y,Id])
    
    cur.execute(" select distinct st_x(dp), st_y(dp)\
    from (\
        select (st_dumppoints(st_transform(st_simplify(way,25),4326))).geom as dp \
            from planet_osm_polygon\
                where osm_id=%s\
        )as bar;"% (Id,))
    for c in cur.fetchall():
        x, y= (c[1],c[0])
        if [x,y,Id] not in modified_ways_nodeList: modified_ways_nodeList.append([x,y,Id])

for Id in modified_relations_ids:
    cur.execute("select distinct st_x(dp), st_y(dp)\
    from (\
        select (st_dumppoints(st_transform(st_simplify(way,25),4326))).geom as dp \
            from  planet_osm_line\
                where osm_id=-%s\
        )as bar;"% (Id,))
    for c in cur.fetchall():
        x, y= (c[1],c[0])
        if [x,y,Id] not in modified_relations_nodeList: modified_relations_nodeList.append([x,y,Id])
    
    cur.execute(" select distinct st_x(dp), st_y(dp)\
    from (\
        select (st_dumppoints(st_transform(st_simplify(way,25),4326))).geom as dp \
            from planet_osm_polygon\
                where osm_id=-%s\
        )as bar;"% (Id,))
    for c in cur.fetchall():
        x, y= (c[1],c[0])
        if [x,y,Id] not in modified_relations_nodeList: modified_relations_nodeList.append([x,y,Id])

for Id in deleted_nodes_ids:
    cur.execute(" select distinct \
    st_x(st_transform(st_simplify(way,25),4326)), st_y(st_transform(st_simplify(way,25),4326)) \
    from planet_osm_point where osm_id=%s;"% (Id,))
    for c in cur.fetchall():
        x, y= (c[1],c[0])
        if [x,y,Id] not in deleted_nodes_nodeList: deleted_nodes_nodeList.append([x,y,Id])

for Id in deleted_ways_ids:
    cur.execute(" select distinct st_x(dp), st_y(dp)\
    from (\
        select (st_dumppoints(st_transform(st_simplify(way,25),4326))).geom as dp \
            from  planet_osm_line\
                where osm_id=%s\
        )as bar;"% (Id,))
    for c in cur.fetchall():
        x, y= (c[1],c[0])
        if [x,y,Id] not in deleted_ways_nodeList: deleted_ways_nodeList.append([x,y,Id])
    
    cur.execute(" select distinct st_x(dp), st_y(dp)\
    from (\
        select (st_dumppoints(st_transform(st_simplify(way,25),4326))).geom as dp \
            from planet_osm_polygon\
                where osm_id=%s\
        )as bar;"% (Id,))
    for c in cur.fetchall():
        x, y= (c[1],c[0])
        if [x,y,Id] not in deleted_ways_nodeList: deleted_ways_nodeList.append([x,y,Id])

for Id in deleted_relations_ids:
    cur.execute("select distinct st_x(dp), st_y(dp)\
    from (\
        select (st_dumppoints(st_transform(st_simplify(way,25),4326))).geom as dp \
            from  planet_osm_line\
                where osm_id=-%s\
        )as bar;"% (Id,))
    for c in cur.fetchall():
        x, y= (c[1],c[0])
        if [x,y,Id] not in deleted_relations_nodeList: deleted_relations_nodeList.append([x,y,Id])
    
    cur.execute(" select distinct st_x(dp), st_y(dp)\
    from (\
        select (st_dumppoints(st_transform(st_simplify(way,25),4326))).geom as dp \
            from planet_osm_polygon\
                where osm_id=-%s\
        )as bar;"% (Id,))
    for c in cur.fetchall():
        x, y= (c[1],c[0])
        if [x,y,Id] not in deleted_relations_nodeList: deleted_relations_nodeList.append([x,y,Id])

conn.close()

#########################################################
#Export files
#########################################################

for t in added_nodes_nodeList:
    nodes_added_file.write(str(t[0])+','+str(t[1])+','+str(t[2])+'\n')
nodes_added_file.close()
for t in added_ways_nodeList:
    ways_added_file.write(str(t[0])+','+str(t[1])+','+str(t[2])+'\n')
ways_added_file.close()
for t in added_relations_nodeList:
    relations_added_file.write(str(t[0])+','+str(t[1])+','+str(t[2])+'\n')
relations_added_file.close()

for t in modified_nodes_nodeList:
    nodes_modified_file.write(str(t[0])+','+str(t[1])+','+str(t[2])+'\n')
nodes_modified_file.close()
for t in modified_ways_nodeList:
    ways_modified_file.write(str(t[0])+','+str(t[1])+','+str(t[2])+'\n')
ways_modified_file.close()
for t in modified_relations_nodeList:
    relations_modified_file.write(str(t[0])+','+str(t[1])+','+str(t[2])+'\n')
relations_modified_file.close()

for t in deleted_nodes_nodeList:
    nodes_deleted_file.write(str(t[0])+','+str(t[1])+','+str(t[2])+'\n')
nodes_deleted_file.close()
for t in deleted_ways_nodeList:
    ways_deleted_file.write(str(t[0])+','+str(t[1])+','+str(t[2])+'\n')
ways_deleted_file.close()
for t in deleted_relations_nodeList:
    relations_deleted_file.write(str(t[0])+','+str(t[1])+','+str(t[2])+'\n')
relations_deleted_file.close()

