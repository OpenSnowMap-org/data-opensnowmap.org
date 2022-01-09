"""
Converts a file from one format to another.
This example shows how to write objects to a file.
"""

import osmium as o
import pdb
import sys

class TagRewrite(o.SimpleHandler):

    def __init__(self, writer):
        super(TagRewrite, self).__init__()
        self.writer = writer

    def node(self, n):
        self.writer.add_node(n)
    def way(self, o):
        self.writer.add_way(self.rewrite(o))
    def relation(self, o):
        self.writer.add_relation(self.rewrite(o))
        
    def rewrite(self, o):
        # if there are no tags we are done
        if not o.tags:
            return o
        
        # new tags should be kept in a list so that the order is preserved
        newtags = []
        
        # pyosmium is much faster writing an original osmium object than
        # a osmium.mutable.*. Therefore, keep track if the tags list was
        # actually changed.
        modified = False
        
        if 'area'  in o.tags and o.tags['area'] == 'yes':
            # only write an empty set of tags
            modified = True
        elif 'ski' in o.tags and (o.tags['ski'] == 'no' or o.tags['ski'] == 'discouraged'):
            # only write an empty set of tags
            modified = True
        elif 'piste:type' in o.tags:
            if o.tags['piste:type'] not in ("nordic","downhill","connection" ,"hike","skitour","sled","ski_jump","fatbike","sleigh" ,"playground","ski_jump_landing","snow_park"):
                newtags.append(("piste:type","other"))
                modified = True
            else:
                newtags.append(("piste:type",o.tags['piste:type']))
                modified = True
                
        elif 'aerialway' in o.tags:
            if o.tags['aerialway'] not in ("gondola","chair_lift","drag_lift","platter","t-bar","magic_carpet","rope_tow","cable_car","j-bar","mixed_lift"):
                newtags.append(("aerialway","other"))
                modified = True
            else:
                newtags.append(("aerialway",o.tags['aerialway']))
                modified = True
        elif 'railway' in o.tags:
            if o.tags['railway'] in ("funicular","incline"):
                newtags.append(("aerialway","other"))
                modified = True
            else:
                # only write an empty set of tags
                modified = True
        
        if 'oneway' in o.tags and not 'highway' in o.tags:
                newtags.append(("oneway",o.tags['oneway']))
                modified = True
                
        if 'piste:oneway' in o.tags:
                newtags.append(("oneway",o.tags['piste:oneway']))
                newtags.append(("piste:oneway",o.tags['piste:oneway']))
                modified = True
        # handle access tag, only on ways
        # access handling of ways member of relations is not handled
        if 'ski' in o.tags and (o.tags['ski'] == 'no' or o.tags['ski'] == 'discouraged'): 
            if 'piste:type' in o.tags and o.tags['piste:type'] in ("nordic","downhill","skitour","ski_jump_landing","snow_park"):
                return
        if 'foot' in o.tags and (o.tags['foot'] == 'no' or o.tags['foot'] == 'discouraged'): 
            if 'piste:type' in o.tags and o.tags['piste:type'] in ("connection" ,"hike"):
                return
        if 'bicycle' in o.tags and (o.tags['bicycle'] == 'no' or o.tags['bicycle'] == 'discouraged'): 
            if 'piste:type' in o.tags and o.tags['piste:type'] in ("fatbike" ):
                return
            
        if modified:
            # We have changed tags. Create a new object as a copy of the
            # original one with the tag list replaced.
            return o.replace(tags=newtags)
        else:
            # Nothing changed, so simply return the original object
            # and discard the tag list we just created.
            return o

if __name__ == '__main__':
    if len(sys.argv) != 3:
        print("Usage: python convert.py <infile> <outfile>")
        sys.exit(-1)

    writer = o.SimpleWriter(sys.argv[2])
    
    TagRewrite(writer).apply_file(sys.argv[1])

    writer.close()


