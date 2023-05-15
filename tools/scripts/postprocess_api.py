#!/usr/bin/env python


import pdb
import psycopg2
import os, sys
from lxml import etree

conn = psycopg2.connect("dbname=pistes_api_osm2pgsql_temp user=osmuser")
cur = conn.cursor()

print("postprocess_api.py post-process relations in the database\n")


#
###########################################################################
print(' Populate the relation_piste_types from every route relation it is a member off')
string = """SELECT member_id, string_agg(distinct(relation_piste_type),';') FROM relations
						WHERE relation_type='route' AND member_type='w'
						GROUP BY member_id;"""
cur.execute(string)
table=cur.fetchall()
print(str(len(table)) + " lines member of routes found")
string=''
i=0

print(" updating " + str(len(table)) + " rows")
for t in table:
	if t[1]:
		string += """
						UPDATE lines set relation_piste_type=('%s')
						WHERE osm_id = %s;""" % (t[1], t[0])
cur.execute(string)
conn.commit()

###########################################################################
print(' Populate the site piste_types column from every element intersecting a landuse=winter_sports')

# ~ It's way faster to compute all intersection before hand instead of scanning trough lines or sites
string="""SELECT a.id , array_agg(distinct(a.typ))
					FROM (
						SELECT sites.osm_id as id, lines.piste_type as typ
						FROM lines, sites
						WHERE sites.site_type='landuse' 
						AND ST_Intersects(lines.geom, ST_ConvexHull(sites.geom))
						
						UNION ALL
						SELECT sites.osm_id as id, routes.relation_piste_type as typ
						FROM routes, sites
						WHERE sites.site_type='landuse' 
						AND ST_Intersects(routes.geom, ST_ConvexHull(sites.geom))
						
						UNION ALL
						SELECT sites.osm_id as id, areas.piste_type as typ
						FROM areas, sites
						WHERE sites.site_type='landuse' 
						AND ST_Intersects(areas.geom, ST_ConvexHull(sites.geom))
					) as a
					GROUP BY a.id;"""
cur.execute(string)
table=cur.fetchall()
print(str(len(table)) + " lines landuse=winter_sports computed")
string=''
for t in table:
	clean=[]
	
	for typ in t[1]:
		if typ:
			clean.append(typ)
	clean_str=';'.join(sorted(set(clean)))
	# ~ print(t)
	# ~ print(clean_str)
	string = """UPDATE sites SET piste_type=('%s')
						WHERE osm_id=%s AND site_type='landuse';""" % (clean_str,t[0])
	cur.execute(string)
	conn.commit()
print("sites updated")


###########################################################################
###########################################################################
#############################################################################
print(' Populate the site piste_types column from every member of a site relation')

cur.execute("select osm_id from sites WHERE site_type='site';")
relations=cur.fetchall()

i=len(relations)
print(i)
for site_id in relations:
	piste_types=[]
	# get members
	s=site_id[0]
	# ~ print(s)
	
	# build longer queries, faster than loops for psycopg
	string=''
	
	cur.execute("select member_id from relations WHERE relation_id=%s and member_type='w';" % (s,))
	members = cur.fetchall()
	# build an array to use 'IN' instead of looping trough each member
	array_string=''
	for m in members:
		array_string += str(m[0])+','
	array_string=array_string[:-1]
	
	if (array_string): # could be empty
		string += """SELECT distinct(piste_type) from lines
									WHERE osm_id in (%s);""" % (array_string)
		cur.execute(string)
		piste_types.append(cur.fetchall())
		string += """SELECT distinct(piste_type) from areas
									WHERE osm_id in (%s);""" % (array_string)
		cur.execute(string)
		piste_types.append(cur.fetchall())
	
	cur.execute("select member_id from relations WHERE relation_id=%s and member_type='r';" % (s,))
	members = cur.fetchall()
	# build an array to use 'IN' instead of looping trough each member
	array_string=''
	for m in members:
		array_string += str(m[0])+','
	array_string=array_string[:-1]
	
	if (array_string):
		string += """SELECT distinct(relation_piste_type) from routes
									WHERE osm_id in (%s);""" % (array_string)
		cur.execute(string)
		piste_types.append(cur.fetchall())
		string += """SELECT distinct(piste_type) from areas
									WHERE osm_id in (%s);""" % (array_string) # Theoritical, not found a single one
		cur.execute(string)
		piste_types.append(cur.fetchall())
	# no piste:type on nodes, maybe we should gather sport=*
	# ~ cur.execute("select member_id from relations WHERE relation_id=%s and member_type='n';" % (s,))
	# ~ members = cur.fetchall()
	# ~ # build an array to use 'IN' instead of looping trough each member
	# ~ array_string=''
	# ~ for m in members:
		# ~ array_string += str(m[0])+','
	# ~ array_string=array_string[:-1]
	# ~ if (array_string):
		# ~ string += """SELECT distinct(piste_type) from points
									# ~ WHERE osm_id in (%s);""" % (array_string)
		# ~ cur.execute(string)
		# ~ piste_types.append(cur.fetchall())
	"""[[('downhill',), ('snow_park',), (None,)], [('downhill',)]]"""
	clean=[]
	for t1 in piste_types:
		for t2 in t1:
			if t2:
				if t2[0]:
					clean.append(t2[0])
	# ~ print(clean)
	clean_str=';'.join(sorted(set(clean)))
	# ~ print(clean_str)
	
	cur.execute("UPDATE sites SET piste_type='%s' WHERE osm_id=%s AND site_type='site';"% (clean_str,s))
	conn.commit()
	i-=1
###########################################################################
###########################################################################
###########################################################################
print(' Populate the sites_ids columns for every member of a site relation')
# recurse down relations once to ways and area included
cur.execute("select osm_id from sites \
			WHERE site_type='site';")
relations=cur.fetchall()

i=len(relations)
print(i)
for site_id in relations:
	# get members
	s=site_id[0]
	# ~ print(s)
	
	# build longer queries, faster than loops for psycopg
	string=''
	
	cur.execute("select member_id from relations WHERE relation_id=%s and member_type='w';" % (s,))
	members = cur.fetchall()
	# build an array to use 'IN' instead of looping trough each member
	array_string=''
	for m in members:
		array_string += str(m[0])+','
	array_string=array_string[:-1]
	
	if (array_string): # could be empty
		string += """update lines set sites_ids= (
			select array_append(sites_ids::bigint[], %s::bigint)
			) WHERE osm_id in (%s);""" % (s,array_string)
			
		"""select array_append(sites_ids::bigint[], 9050227::bigint)
			) WHERE osm_id in (30975432,30975431,404045749,30975430,573296589,573296590,33186365,30946047,30975427,30705364,572874184,30975429,30975433,30975434,573296588,30975435,644662130,30975436,30705362,404045747,30705361,30975437,30975438,56355065,30975440,334780938,30705360,572871674,573293149,30975459,30975451,30705366,33277896,33186361,56355061,484353991,30975457,30975455,30975458,30975452,381506010,381506005,683748072,30705354,33277905,30946039,33277897,484353995,254231988,30975456,484353992,30975446,30975450,30705359,30975442,30975445,683748069,660892051,33186360,474931076,30975447,33186363,474931075,56355063,30946042,30975443,254231159,30946045,484353994,30975461,30705357,30975466,30975462,30975453,30975454,484353993,30975468,33186358,30705358,404045750,33186357,30975473,30975472,404045751,30975471,404045748,30975470,33186359,30975475,30975474,404045752,30975476,644654908,30946051,30946054,30946057,30705365,30946049,30946053,30946044,30975444,573296592,625597409,625597407,573296593,625597410,30975469,30975460,33186366,484353996,33186362,473676234,473676232,835337680);
		"""
		string += """update areas set sites_ids= (
			select array_append(sites_ids::bigint[], %s::bigint)
			) WHERE osm_id in (%s) AND type='w';""" % (s,array_string)
	
	cur.execute("select member_id from relations WHERE relation_id=%s and member_type='r';" % (s,))
	members = cur.fetchall()
	# build an array to use 'IN' instead of looping trough each member
	array_string=''
	for m in members:
		array_string += str(m[0])+','
	array_string=array_string[:-1]
	
	if (array_string):
		string += """update routes set sites_ids= (
			select array_append(sites_ids::bigint[], %s::bigint)
			) WHERE osm_id in (%s);""" % (s,array_string)
		string += """update areas set sites_ids= (
			select array_append(sites_ids::bigint[], %s::bigint)
			) WHERE osm_id in (%s) AND type='r';""" % (s,array_string) # Theoritical, not found a single one
	
	# One level of recursion ways(route(site)))
	
	if (array_string):
		cur.execute("select member_id from relations WHERE relation_id in (%s) and member_type='w';" % (array_string,))
		members = cur.fetchall()
	for m in members:
		array_string += str(m[0])+','
	array_string=array_string[:-1]
	if (array_string):
		string += """update lines set sites_ids= (
			select array_append(sites_ids::bigint[], %s::bigint)
			) WHERE osm_id in (%s);""" % (s,array_string)
		string += """update areas set sites_ids= (
			select array_append(sites_ids::bigint[], %s::bigint)
			) WHERE osm_id in (%s) AND type='w';""" % (s,array_string)
	
	cur.execute("select member_id from relations WHERE relation_id=%s and member_type='n';" % (s,))
	members = cur.fetchall()
	# build an array to use 'IN' instead of looping trough each member
	array_string=''
	for m in members:
		array_string += str(m[0])+','
	array_string=array_string[:-1]
	if (array_string):
		string += """update points set sites_ids= (
			select array_append(sites_ids::bigint[], %s::bigint)
			) WHERE osm_id in (%s);""" % (s,array_string)
	

	cur.execute(string)
	i-=1
	# ~ print(i)
conn.commit()

###########################################################################
###########################################################################
###########################################################################
print(' Now build the convex_hull geometry for the site relations:')
i=len(relations)
print(i)
for site_id in relations:
	# get members
	s=site_id[0]
	string= """UPDATE sites SET geom=(
		SELECT st_convexHull(st_collect((geom)))
		FROM (
			SELECT lines.geom as geom from lines
			WHERE osm_id IN (
				SELECT member_id FROM relations 
				WHERE relation_id=%s
				AND member_type='w'
				)
			UNION ALL
			SELECT areas.geom as geom from areas
			WHERE osm_id IN (
				SELECT member_id FROM relations 
				WHERE relation_id=%s
				AND member_type='w'
				) 
			UNION ALL
			SELECT routes.geom as geom from routes
			WHERE osm_id IN (
				SELECT member_id FROM relations 
				WHERE relation_id=%s
				AND member_type='r'
				) 
			UNION ALL
			SELECT points.geom as geom from points
			WHERE osm_id IN (
				SELECT member_id FROM relations 
				WHERE relation_id=%s
				AND member_type='n'
				) 
			) as geom
			)
		WHERE osm_id = %s;""" % (s,s,s,s,s)
	cur.execute(string)
	i-=1
	# ~ print(i)
conn.commit()

###########################################################################
###########################################################################
###########################################################################
print(' Populate the landuse_ids row for every element included in a landuse=winter_sport')
print(' Also insert fake members into the relations table')
# Note: landuse=wintersports are imported as lines
# ~ It's way faster to compute all intersection before hand instead of scanning trough lines or sites


string="""SELECT lines.osm_id, sites.osm_id
FROM lines, sites
WHERE sites.site_type='landuse' 
AND ST_Contains(ST_ConvexHull(sites.geom), lines.geom);"""
cur.execute(string)
table=cur.fetchall()
print(str(len(table)) + " lines intersections computed")
string=''
for t in table:
	string += """UPDATE lines SET landuses_ids= (select array_append(landuses_ids::bigint[], %s::bigint))
						WHERE osm_id=%s;""" % (t[1], t[0])
cur.execute(string)
conn.commit()
print("lines updated")
string=''
for t in table:
	string += """INSERT INTO relations(relation_id,member_id,relation_type,relation_piste_type,member_type)
							VALUES(%s,%s,'landuse','','w');""" % (t[1], t[0])
cur.execute(string)
conn.commit()
print("members inserted in relations table")

string="""SELECT routes.osm_id, sites.osm_id
FROM routes, sites
WHERE sites.site_type='landuse' 
AND ST_Contains(ST_ConvexHull(sites.geom), routes.geom);"""
cur.execute(string)
table=cur.fetchall()
print(str(len(table)) + " routes intersections computed")

string=''
for t in table:
	string += """UPDATE routes SET landuses_ids= (select array_append(landuses_ids::bigint[], %s::bigint))
						WHERE osm_id=%s;""" % (t[1], t[0])
cur.execute(string)
conn.commit()
print("routes updated")
string=''
for t in table:
	string += """INSERT INTO relations(relation_id,member_id,relation_type,relation_piste_type,member_type)
							VALUES(%s,%s,'landuse','','r');""" % (t[1], t[0])
cur.execute(string)
conn.commit()
print("members inserted in relations table")

string="""SELECT areas.osm_id, sites.osm_id
FROM areas, sites
WHERE sites.site_type='landuse' 
AND ST_Contains(ST_ConvexHull(sites.geom), areas.geom);"""
cur.execute(string)
table=cur.fetchall()
print(str(len(table)) + " areas intersections computed")

string=''
for t in table:
	string += """UPDATE areas SET landuses_ids= (select array_append(landuses_ids::bigint[], %s::bigint))
						WHERE osm_id=%s;""" % (t[1], t[0])
cur.execute(string)
conn.commit()
print("areas updated")
string=''
for t in table:
	string += """INSERT INTO relations(relation_id,member_id,relation_type,relation_piste_type,member_type)
							VALUES(%s,%s,'landuse','','w');""" % (t[1], t[0])
cur.execute(string)
conn.commit()
print("members inserted in relations table")

string="""SELECT points.osm_id, sites.osm_id
FROM points, sites
WHERE sites.site_type='landuse' 
AND ST_Contains(ST_ConvexHull(sites.geom), points.geom);"""
cur.execute(string)
table=cur.fetchall()
print(str(len(table)) + " points intersections computed")

string=''
for t in table:
	string += """UPDATE points SET landuses_ids= (select array_append(landuses_ids::bigint[], %s::bigint))
						WHERE osm_id=%s;""" % (t[1], t[0])
cur.execute(string)
conn.commit()
print("points updated")
string=''
for t in table:
	string += """INSERT INTO relations(relation_id,member_id,relation_type,relation_piste_type,member_type)
							VALUES(%s,%s,'landuse','','n');""" % (t[1], t[0])
cur.execute(string)
conn.commit()
print("members inserted in relations table")


exit()



