#!/usr/bin/python
"""
Parses an osm file add a "member_of" tag if an element is a member of a relation.
"""

from lxml import etree
from copy import deepcopy

#~ import pdb
import os, sys

global maxWayId
maxWayId = 0

#
def addTag(way,t, attribute):
    tags=way.findall('tag')
    for tag in tags:
        if tag.get('k') == t: way.remove(tag)
    newMember = etree.Element("tag",k=t, v=attribute)
    way.append(newMember)
    
    return True
#
def cleanWay(way):
    tags = way.findall('tag')
    ids=[]
    for tag in tags:
        if tag.get('k') not in ["aerialway", "oa_downhill", "oa_nordic", "oa_hike", "oa_skitour", "name", "layer"]:
            way.remove(tag)
    return True
#
def deepCleanWay(way):
    tags = way.findall('tag')
    for tag in tags:
        way.remove(tag)
    return True
#

WORK_DIR="/home/website/Planet/"

osmDoc=etree.parse(sys.argv[1])
outFile=open(sys.argv[2],'w')


osmRoot= osmDoc.getroot()
osmRoot.set('generator', 'osmand_prepro.py for ski map by Yves Cainaud')
ways = osmDoc.findall('way')

relations = osmDoc.findall('relation')
ways = osmDoc.findall('way')
nodes = osmDoc.findall('node')

print "nodes:", len (nodes)
print "ways:", len(ways)
		
ways = osmDoc.findall('way')
nodes = osmDoc.findall('node')

relationList={}
wayList={}
nodeList={}

for node in nodes:
	# create a dict of nodes by id
	nodeList[node.get('id')]=node
	
for way in ways:
	# create a dict of ways by id
	wayList[way.get('id')]=way

for relation in relations:
	# create a dict of relations by id
	relationList[relation.get('id')]=relation

## clean for easy check of the xml
#for node in nodes:
	#osmRoot.remove(node)
	
#for way in ways:
	#nds= way.findall('nd')
	#for nd in nds:
		#way.remove(nd)
		
for way in ways:
	tags = way.findall('tag')
	for tag in tags:
		if tag.get('k') == 'aerialway':
			#Simplify drag-type lift rendering
			if tag.get('v') in ['t-bar', 'j-bar', 'platter', 'rope_tow', 'magic_carpet']:
				way.remove(tag)
				addTag(way,"aerialway", "drag_lift") 
	tags = way.findall('tag')
	difficulty = "unknow"
	for tag in tags:
		if tag.get('k') == "piste:difficulty":
			if tag.get('v') in ['novice', 'easy', 'advanced', 'expert', 'intermediate', 'freeride']:
				difficulty = tag.get('v')
				
	for tag in tags:
		if tag.get('k') == "piste:type":
			if tag.get('v') == "downhill":
				addTag(way,"oa_downhill", difficulty)
			if tag.get('v') == "nordic":
				addTag(way,"oa_nordic", difficulty)
			if tag.get('v') == "skitour":
				addTag(way,"oa_skitour", difficulty)
			if tag.get('v') == "hike":
				addTag(way,"oa_hike", difficulty)
		if tag.get('k') == "piste:name":
			addTag(way,"name", tag.get('v'))
		if tag.get('k') == 'aerialway':                    
			# add a tag on the central node to place the lift icon
			nodes = way.findall('nd')
			mid_ref = nodes[int(len(nodes)/2)].get('ref')
			newMember = etree.Element("tag",k='oa_aerialway', v=tag.get('v'))
			try: nodeList[mid_ref].append(newMember)
			except: pass

# Put relations on ways if not already
for relation in relations:
	members= relation.findall('member')
	tags = relation.findall('tag')
	for tag in tags:
		if tag.get('k') == "piste:type":
			if tag.get('v') == "nordic":
				for member in members:
					if member.get('type') == 'way':
						try: way=wayList[''+member.get('ref')]
						except: break
						waytags=way.findall('tag')
						replace = True
						for waytag in waytags:
							if waytag.get('k') == "oa_nordic": replace = False
						if replace:
							addTag(way,"oa_nordic", "route")
		if tag.get('k') == "piste:type":
			if tag.get('v') == "skitour":
				for member in members:
					if member.get('type') == 'way':
						try: way=wayList[''+member.get('ref')]
						except: break
						waytags=way.findall('tag')
						replace = True
						for waytag in waytags:
							if waytag.get('k') == "oa_skitour": replace = False
						if replace:
							addTag(way,"oa_skitour", "route")
		if tag.get('k') == "piste:type":
			if tag.get('v') == "hike":
				for member in members:
					if member.get('type') == 'way':
						try: way=wayList[''+member.get('ref')]
						except: break
						waytags=way.findall('tag')
						replace = True
						for waytag in waytags:
							if waytag.get('k') == "oa_hike": replace = False
						if replace:
							addTag(way,"oa_hike", "route")
							
		if tag.get('k') == "name":
			for member in members:
				if member.get('type') == 'way':
					try: way=wayList[''+member.get('ref')]
					except: break
					waytags=way.findall('tag')
					replace = True
					for waytag in waytags:
						if waytag.get('k') == "name": 
							old=waytag.get('v')
							replace = False
					if replace:
						addTag(way,"name", tag.get('v'))
					else:
						addTag(way,"name", old +' - '+ tag.get('v'))
		
		if tag.get('k') == "piste:name":
			for member in members:
				if member.get('type') == 'way':
					try: way=wayList[''+member.get('ref')]
					except: break
					waytags=way.findall('tag')
					replace = True
					for waytag in waytags:
						if waytag.get('k') == "name": 
							old=waytag.get('v')
							replace = False
					if replace:
						addTag(way,"name", tag.get('v'))
					else:
						addTag(way,"name", old +' - '+ tag.get('v'))

for way in ways:
	addTag(way,'layer', '10')
	cleanWay(way)

for relation in relations:
	osmRoot.remove(relation)

for way in ways:
	nid='-'+ way.get('id')
	way.set('id', nid)
	
outFile.write("<?xml version=\"1.0\" encoding=\"UTF-8\"?>")
outFile.write(etree.tostring(osmDoc))


