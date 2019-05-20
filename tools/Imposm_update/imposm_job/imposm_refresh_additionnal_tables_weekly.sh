#~ SECONDS=0
#~ echo "REFRESH MATERIALIZED VIEW pistes_routes;" |psql -d imposm
#~ echo "ANALYSE pistes_routes;" |psql -d imposm
#~ duration=$SECONDS
#~ echo "pistes_routes view done in $(($duration / 60)) min $(($duration % 60))s."

#~ SECONDS=0
#~ echo "REFRESH MATERIALIZED VIEW pistes_sites;" |psql -d imposm
#~ echo "ANALYSE pistes_sites;" |psql -d imposm
#~ duration=$SECONDS
#~ echo "pistes_sites view done in $(($duration / 60)) min $(($duration % 60))s."

# landuse_ressorts
SECONDS=0
echo "DROP TABLE landuse_resorts;" |psql -d imposm -U imposm

echo "CREATE TABLE landuse_resorts AS SELECT * FROM osm_resorts;

ALTER TABLE landuse_resorts ADD members_types text;

UPDATE landuse_resorts SET members_types = concat_ws(
    ';', 
    members_types,
    (SELECT string_agg(distinct pistes_routes.type::text, ';')
        FROM pistes_routes
        WHERE ST_Intersects(pistes_routes.geometry,landuse_resorts.geometry)
    )
);
UPDATE landuse_resorts SET members_types = concat_ws(
    ';',
    members_types,
    (SELECT string_agg(distinct osm_pistes_ways.type::text, ';')
        FROM osm_pistes_ways
        WHERE ST_Intersects(osm_pistes_ways.geometry,landuse_resorts.geometry)
    )
);
UPDATE landuse_resorts SET members_types = concat_ws(
    ';',
    members_types,
    (SELECT string_agg(distinct osm_pistes_area.type::text, ';')
        FROM osm_pistes_area
        WHERE ST_Intersects(osm_pistes_area.geometry,landuse_resorts.geometry)
    )
);
UPDATE landuse_resorts SET members_types = concat_ws(
    ';',
    members_types,
    (SELECT string_agg(distinct osm_sport_ways.type::text, ';')
        FROM osm_sport_ways
        WHERE ST_Intersects(osm_sport_ways.geometry,landuse_resorts.geometry)
    )
);
UPDATE landuse_resorts SET members_types = concat_ws(
    ';',
    members_types,
    (SELECT string_agg(distinct osm_sport_nodes.type::text, ';')
        FROM osm_sport_nodes
        WHERE ST_Intersects(osm_sport_nodes.geometry,landuse_resorts.geometry)
    )
);" |psql -d imposm -U imposm
echo "alter table landuse_resorts owner to imposm;" |psql -d imposm -U imposm


# Faudrait aussi s'assurer d'avoir plus de 3 ways ...
#~ SELECT 363196 => autant que de landusages
echo "CREATE INDEX idx_landuse_resorts_geom ON landuse_resorts USING gist (geometry);" |psql -d imposm -U imposm

echo "CLUSTER landuse_resorts USING idx_landuse_resorts_geom;" |psql -d imposm -U imposm

echo "ANALYSE landuse_resorts;" |psql -d imposm -U imposm


duration=$SECONDS
echo "landuse_resorts table done in $(($duration / 60)) min $(($duration % 60))s."


