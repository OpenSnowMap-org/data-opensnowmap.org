#!/usr/bin/env python


import pdb
import psycopg2
import os, sys
from lxml import etree

conn = psycopg2.connect("dbname=pistes-mapnik-tmp user=mapnik")
cur = conn.cursor()

# normalize grooming tag
#
cur.execute("update planet_osm_line set \"piste:grooming\"= 'classic;skating' \
			where \"piste:grooming\"= 'classic+skating';")
conn.commit()

# copy sites ids as a in_site tag for it's members
#
print "relation_down.py: Normalize groomin and post-process relations\n"
try: 
	cur.execute("ALTER TABLE planet_osm_line ADD in_site bigint[];")
	conn.commit()
except:
	conn.rollback()
try: 
	cur.execute("ALTER TABLE planet_osm_polygon ADD in_site bigint[];")
	conn.commit()
except:
	conn.rollback()
try: 
	cur.execute("ALTER TABLE planet_osm_point ADD in_site bigint[];")
	conn.commit()
except:
	conn.rollback()

cur.execute("select id, parts from planet_osm_rels \
			WHERE array_to_string(tags, ',') like '%,site,%' ;")
relations=cur.fetchall()

i=len(relations)

for relation in relations:
	site_id=relation[0]
	for memberid in relation[1]:
		# populate in_site for points
		cur.execute("update planet_osm_point set in_site= (\
					select array_append(in_site::bigint[], %s::bigint)\
					from planet_osm_line where osm_id = %s limit 1) \
				where osm_id = %s;" % (site_id, memberid, memberid))
		# populate in_site for ways
		cur.execute("update planet_osm_line set in_site= (\
					select array_append(in_site::bigint[], %s::bigint)\
					from planet_osm_line where osm_id = %s limit 1) \
				where osm_id = %s;" % (site_id, memberid, memberid))
		cur.execute("update planet_osm_polygon set in_site= (\
					select array_append(in_site::bigint[], %s::bigint)\
					from planet_osm_polygon where osm_id = %s limit 1) \
				where osm_id = %s;" % (site_id, memberid, memberid))
		# populate in_site for relations
		cur.execute("update planet_osm_line set in_site= (\
					select array_append(in_site::bigint[], %s::bigint)\
					from planet_osm_line where osm_id = %s limit 1) \
				where osm_id = %s;" % (site_id, -memberid, -memberid))
		
		
	i-=1
	#~ sys.stdout.write("%s \r" % (i) )
	#~ sys.stdout.flush()
conn.commit()

# copy relations ids as a member_of tag for it's members
#
try: 
	cur.execute("ALTER TABLE planet_osm_line ADD member_of bigint[];")
	conn.commit()
except:
	conn.rollback()
try: 
	cur.execute("ALTER TABLE planet_osm_polygon ADD member_of bigint[];")
	conn.commit()
except:
	conn.rollback()
try: 
	cur.execute("ALTER TABLE planet_osm_point ADD member_of bigint[];")
	conn.commit()
except:
	conn.rollback()

cur.execute("select id, parts from planet_osm_rels \
			WHERE array_to_string(tags, ',') like '%,route,%' ;")
relations=cur.fetchall()

i=len(relations)

for relation in relations:
	route_id=relation[0]
	for memberid in relation[1]:
		# populate member_of for ways
		cur.execute("update planet_osm_line set member_of= (\
					select array_append(member_of::bigint[], %s::bigint)\
					from planet_osm_line where osm_id = %s limit 1) \
				where osm_id = %s;" % (route_id, memberid, memberid))
		cur.execute("update planet_osm_polygon set member_of= (\
					select array_append(member_of::bigint[], %s::bigint)\
					from planet_osm_polygon where osm_id = %s limit 1) \
				where osm_id = %s;" % (route_id, memberid, memberid))
		# populate member_of for points
		cur.execute("update planet_osm_point set member_of= (\
					select array_append(member_of::bigint[], %s::bigint)\
					from planet_osm_point where osm_id = %s limit 1) \
				where osm_id = %s;" % (route_id, memberid, memberid))
		# populate in_site for ways and nodes members of routes relations
		cur.execute("select in_site from planet_osm_line \
					where osm_id = %s;" % (-route_id))
		
		#~ sitesids=cur.fetchall()
		#~ if len(sitesids) > 0:
			#~ sitesids=sitesids[0][0]
			#~ if sitesids:
				#~ for siteid in sitesids:
					#~ # populate in_site for ways members of routes relations
					#~ cur.execute("update planet_osm_line set in_site= (\
								#~ select array_append(in_site::bigint[], %s::bigint)\
								#~ from planet_osm_line where osm_id = %s limit 1) \
							#~ where osm_id = %s;" % (siteid, memberid, memberid))
					#~ cur.execute("update planet_osm_polygon set in_site= (\
								#~ select array_append(in_site::bigint[], %s::bigint)\
								#~ from planet_osm_polygon where osm_id = %s limit 1) \
							#~ where osm_id = %s;" % (siteid, memberid, memberid))
					#~ # populate in_site for nodes members of routes relations
					#~ cur.execute("update planet_osm_point set in_site= (\
								#~ select array_append(in_site::bigint[], %s::bigint)\
								#~ from planet_osm_point where osm_id = %s limit 1) \
							#~ where osm_id = %s;" % (siteid, memberid, memberid))
		
	i-=1
	#~ sys.stdout.write("%s \r" % (i) )
	#~ sys.stdout.flush()
conn.commit()


