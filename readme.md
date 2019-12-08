This set of script are dedicated to maintain Opensnowmap.org server data up-to-date.

The following scripts run daily with a cron job:

    01-planet_update.sh 
        Update complete planet database with osmctools' osmupdate
        Provide state.txt for opensnowmap.org website
        
    02-filter.sh
        Filter planet file for winter-sport related elements with osmctools' osmfilter => planet_pistes.osm
        Filter planet file for site=piste relations
        Archive daily planet_pistes.osm
        Create daily, weekly and monthly planet_pistes.osc diff files with Osmosis
        Create daily, weekly and monthly *.tsv diff files with sed for display on opensnowmap.org website
        
    03-db_update.sh
        Load complete planet_pistes.osm datatbase with osm2pgsql in temporary DB
        Postprocess sites (relations / landuse) in DB (make_sites.py)
        Postprocess relations in DB (relations_down.py), add in_site and member_of tags
        Create a expired_tiles.lst of tiles to expire from actual and temporary DB (list_expired.py)
        Stop renderd
        Stop actual DB, replace it with temporary DB
        Update mapnik styles depending on relation colour=* tags and manual offsets
        Restart renderd
        Expire tiles wth renderd_expired
        Compute stats for opensnowmap.org website (pistes-stat2json.sh)
        
    04-pistes_imposm_reload.sh
        Load complete planet_pistes.osm datatbase with imposm in temporary DB
        Create the additionnal table for routes and resorts
        Swap temp and actual DB
        
    06-pgsnapshot.sh
        Load complete planet_pistes.osm datatbase with osmosis in temporary pgsnapshot DB
        (See in config/ for the customization to the pgsnapshot schema)
        Swap temp and actual pgsnapshot DB
        From time to time, create a list of ressorts (resorts.json) with calls to Nominatim (resort_list.py)
    
Other scripts run manually or monthly:

    make_mbtiles.sh (monthly)
        create *.mbtiles files with Geofabrik's meta2tile from all the server tiles z0 to z16
        
    expire.sh
        Run the tile expiry script list_expired.py from two archived files
    get_colored_relations.sh
        get a list of lonlat where relations with the color tags are, in order to check for manual offsets to add
        
    list_all_metatiles.py, list_all_tiles.py
        create a tile list from DB
        
    osmand_pistes.py
        not used anymore, was from the time Osmand did not provide the ski pistes in the .obf files.
        
    render2sqlite.py
        in deprecation, was rendering tiles to sqlite, replaced by *.mbtiles
        
    tile-list-from-db.py, tile-list-not-unique.py
        deprecated
