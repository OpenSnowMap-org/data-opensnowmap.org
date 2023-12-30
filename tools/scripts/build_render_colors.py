#!/usr/bin/env python3


import pdb
import mapnik
import psycopg2
import os, sys, re
import datetime
import pdb
import json
import copy
import webcolors

BARE=False

def deluma(color,factor):
    # reduce color luma by a given factor. 
    r,g,b,a=(color.r, color.g, color.b, color.a)
    r=int(r*(1-0.3*factor))
    g=int(g*(1-0.59*factor))
    b=int(b*(1-0.11*factor))
    
    return mapnik.Color(r,g,b,a)
#
def lighten(color,factor):
    r,g,b,a=(color.r, color.g, color.b, color.a)
    r = int((1-factor)*r + factor*255)
    g = int((1-factor)*g + factor*255)
    b = int((1-factor)*b + factor*255)
    return mapnik.Color(r,g,b,a)
    
def isColor(str):
    try :
        mapnik.Color(str)
        return True
    except:
        return False
#
def is_int(s):
    try:
        int(s)
        return True
    except ValueError:
        return False
        
    

db="dbname=pistes_imposm_tmp user=imposm"
conn = psycopg2.connect(db)
cur = conn.cursor()
cur.execute("""ALTER TABLE osm_pistes_routes 
				ADD COLUMN IF NOT EXISTS nordic_route_colour text DEFAULT '',
				ADD COLUMN IF NOT EXISTS nordic_route_render_colour text DEFAULT '';""")
conn.commit()

cur.execute("""UPDATE osm_pistes_routes
				SET nordic_route_colour = coalesce(tags->'color', tags->'colour')
				WHERE tags->'color' is not null or tags->'colour' is not null;""")
conn.commit()

cur.execute("""select osm_id, nordic_route_colour from osm_pistes_routes where nordic_route_colour is not null;""")

routesResult=cur.fetchall()
routes_ids=[]
colors=[]
for r in routesResult:
    color_tag=r[1]
    route_id=r[0] 
    if color_tag == '': continue
    if not route_id in routes_ids:
        routes_ids.append(route_id)
        if isColor(color_tag):
            color=mapnik.Color(color_tag)
            color=lighten(deluma(color,0.25),0.3)
            colors.append(color.to_hex_string())
        elif isColor('#'+color_tag):
            color=mapnik.Color('#'+color_tag)
            color=lighten(deluma(color,0.25),0.3)
            colors.append(color.to_hex_string())
        elif isColor(color_tag.split(';')[0]):
            color=mapnik.Color(color_tag.split(';')[0])
            color=lighten(deluma(color,0.25),0.3)
            colors.append(color.to_hex_string())
        elif isColor(color_tag.split('/')[0]):
            color=mapnik.Color(color_tag.split('/')[0])
            color=lighten(deluma(color,0.25),0.3)
            colors.append(color.to_hex_string())
        elif isColor(color_tag.split(' ')[0]):
            color=mapnik.Color(color_tag.split(' ')[0])
            color=lighten(deluma(color,0.25),0.3)
            colors.append(color.to_hex_string())
        else:
            print(color_tag)
            colors.append('')

sql=""
transactions=0
for i in range(0,len(routes_ids)-1):
    transactions+=1
    sql+="""UPDATE osm_pistes_routes SET nordic_route_render_colour='%s'
            WHERE osm_id=%s;""" % (colors[i], routes_ids[i])
    if transactions == 50:
        cur.execute(sql)
        conn.commit()
        sql = ""
        transactions=0
cur.execute(sql)
conn.commit()
cur.close()
conn.close()

