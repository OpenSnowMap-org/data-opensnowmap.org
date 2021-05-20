#~ Get timestamp
import sys
# ~ import pyosmium
# ~ import pdb
from osmium.replication import server as rserv
svr = rserv.ReplicationServer("https://planet.osm.org/replication/hour/", "osc.gz")
# ~ pdb.set_trace()
state=svr.get_state_info(int(sys.argv[1]))
#~ OsmosisState(sequence=4523760, timestamp=datetime.datetime(2021, 5, 2, 5, 10, 12, tzinfo=datetime.timezone.utc))
#~ OsmosisState(sequence=1, timestamp=datetime.datetime(2012, 9, 12, 8, 15, 45, tzinfo=datetime.timezone.utc))
print(state.timestamp.strftime("%m/%d/%Y %H:%M:%S %Z"))
