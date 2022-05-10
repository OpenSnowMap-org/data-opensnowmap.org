#!/usr/bin/python
#~ Get timestamp
import sys
# ~ import pyosmium
# ~ import pdb
from osmium.replication import server as rserv
# ~ pdb.set_trace()
server=sys.argv[2]
svr = rserv.ReplicationServer(server,"osc.gz")
state=svr.get_state_info(int(sys.argv[1]))
#~ OsmosisState(sequence=4523760, timestamp=datetime.datetime(2021, 5, 2, 5, 10, 12, tzinfo=datetime.timezone.utc))
#~ OsmosisState(sequence=1, timestamp=datetime.datetime(2012, 9, 12, 8, 15, 45, tzinfo=datetime.timezone.utc))
# ~ 2021-06-27T14:50:01Z
print(state.timestamp.strftime("%Y-%m-%dT%H:%M:%SZ"))
