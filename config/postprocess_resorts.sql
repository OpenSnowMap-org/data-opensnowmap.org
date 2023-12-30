
CREATE TABLE pistes_sites AS (
    SELECT 
        osm_pistes_sites.osm_id as osm_id,
        osm_pistes_sites.name as name,
    
        array_to_string(array_agg(distinct osm_pistes_ways.piste_type::text) 
        || array_agg(distinct pistes_routes.piste_type::text)
        || array_agg(distinct osm_pistes_area.piste_type::text)
        || array_agg(distinct osm_other_ways.piste_type::text)
        || array_agg(distinct osm_other_nodes.piste_type::text)
        ,';') 
        AS members_types,
    
        ST_ConvexHull(ST_Collect(
        ARRAY[
        ST_Collect(osm_pistes_ways.geometry),
        ST_Collect(pistes_routes.geometry),
        ST_Collect(osm_pistes_area.geometry),
        ST_Collect(osm_other_ways.geometry),
        ST_Collect(osm_other_nodes.geometry)
        ]
        ))::geometry(Geometry, 3857) 
        AS geometry
    
    FROM 
        osm_pistes_sites
    LEFT JOIN osm_pistes_site_members 
        ON (osm_pistes_sites.osm_id=osm_pistes_site_members.osm_id)
    LEFT JOIN osm_pistes_ways 
        ON (osm_pistes_ways.osm_id=osm_pistes_site_members.member)
    LEFT JOIN pistes_routes 
        ON (pistes_routes.osm_id=-osm_pistes_site_members.member)
    LEFT JOIN osm_pistes_area 
        ON (osm_pistes_area.osm_id=osm_pistes_site_members.member)
    LEFT JOIN osm_other_ways 
        ON (osm_other_ways.osm_id=osm_pistes_site_members.member)
    LEFT JOIN osm_other_nodes 
        ON (osm_other_nodes.osm_id=osm_pistes_site_members.member)
    GROUP BY osm_pistes_sites.osm_id, osm_pistes_sites.name
    );

CREATE INDEX idx_sites_geom ON pistes_sites USING gist (geometry);
ANALYSE pistes_sites;

CREATE TABLE landuse_resorts AS SELECT * FROM osm_resorts;

ALTER TABLE landuse_resorts ADD members_types text;

UPDATE landuse_resorts SET members_types = concat_ws(
    ';', 
    members_types,
    (SELECT string_agg(distinct pistes_routes.piste_type::text, ';')
        FROM pistes_routes
        WHERE ST_Intersects(pistes_routes.geometry,landuse_resorts.geometry)
    )
);
UPDATE landuse_resorts SET members_types = concat_ws(
    ';',
    members_types,
    (SELECT string_agg(distinct osm_pistes_ways.piste_type::text, ';')
        FROM osm_pistes_ways
        WHERE ST_Intersects(osm_pistes_ways.geometry,landuse_resorts.geometry)
    )
);
UPDATE landuse_resorts SET members_types = concat_ws(
    ';',
    members_types,
    (SELECT string_agg(distinct osm_pistes_area.piste_type::text, ';')
        FROM osm_pistes_area
        WHERE ST_Intersects(osm_pistes_area.geometry,landuse_resorts.geometry)
    )
);
UPDATE landuse_resorts SET members_types = concat_ws(
    ';',
    members_types,
    (SELECT string_agg(distinct osm_other_ways.piste_type::text, ';')
        FROM osm_other_ways
        WHERE ST_Intersects(osm_other_ways.geometry,landuse_resorts.geometry)
    )
);
UPDATE landuse_resorts SET members_types = concat_ws(
    ';',
    members_types,
    (SELECT string_agg(distinct osm_other_nodes.piste_type::text, ';')
        FROM osm_other_nodes
        WHERE ST_Intersects(osm_other_nodes.geometry,landuse_resorts.geometry)
    )
);
CREATE INDEX idx_landuse_resorts_geom ON landuse_resorts USING gist (geometry);
CLUSTER landuse_resorts USING idx_landuse_resorts_geom;
ANALYSE landuse_resorts;
