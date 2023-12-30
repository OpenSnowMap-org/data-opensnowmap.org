-- ~ #Fix imported geometries, otherwise we have issue with 
-- ~ #collection of polygons at the output of ST_LineMerge
UPDATE osm_pistes_route_members
        SET geometry=ST_ExteriorRing(geometry)
        WHERE ST_GeometryType(osm_pistes_route_members.geometry)='ST_Polygon'
    ;
-- ~ UPDATE osm_pistes_route_members SET geometry=ST_ReducePrecision(geometry, 1.0);

CREATE TABLE pistes_routes AS (
    SELECT 
        osm_pistes_routes.osm_id as osm_id,
        osm_pistes_routes.tags as tags,
        string_agg(distinct osm_pistes_routes.name,';') as name,
        string_agg(distinct osm_pistes_routes.piste_type,';') as piste_type,
        string_agg(distinct osm_pistes_routes.grooming,';') as grooming,
        bool_and(osm_pistes_routes.gladed) as gladed,
        bool_and(osm_pistes_routes.patrolled) as patrolled,
        bit_and(osm_pistes_routes.oneway) as oneway,
        string_agg(distinct osm_pistes_routes.piste_name,';') as piste_name,
        string_agg(distinct osm_pistes_routes.piste_ref,';') as piste_ref,
        string_agg(distinct osm_pistes_routes.ref,';') as ref,
        string_agg(distinct osm_pistes_routes.color,';') as color,
        string_agg(distinct osm_pistes_routes.colour,';') as colour,
        string_agg(distinct osm_pistes_routes.nordic_route_colour,';') as nordic_route_colour,
        string_agg(distinct osm_pistes_routes.nordic_route_render_colour,';') as nordic_route_render_colour,
        0 as nordic_route_offset,
        string_agg(distinct osm_pistes_routes.difficulty,';') as difficulty,
        bool_and(osm_pistes_routes.lit1) as lit1,
        bool_and(osm_pistes_routes.lit2) as lit2,
        bool_and(osm_pistes_routes.abandoned1) as abandoned1,
        bool_and(osm_pistes_routes.abandoned2) as abandoned2,
        ST_LineMerge(
            ST_CollectionExtract(
                ST_Collect(osm_pistes_route_members.geometry)
                ,2)
        )::geometry(Geometry, 3857) AS geometry
    FROM 
    osm_pistes_routes
    JOIN
    osm_pistes_route_members ON (osm_pistes_routes.osm_id=osm_pistes_route_members.osm_id)
    GROUP BY osm_pistes_routes.osm_id, osm_pistes_routes.tags
    );

CREATE INDEX idx_routes_geom ON pistes_routes USING gist (geometry);

CLUSTER pistes_routes USING idx_routes_geom;
ANALYSE pistes_routes;



ALTER TABLE osm_pistes_route_members
ADD COLUMN nordic_route_offset integer DEFAULT 0,
ADD COLUMN nordic_route_colour text DEFAULT '',
ADD COLUMN nordic_route_length integer DEFAULT 1000000,
ADD COLUMN nordic_route_render_colour text DEFAULT '',
ADD COLUMN direction_to_route integer DEFAULT 0;

ALTER TABLE osm_pistes_ways
ADD COLUMN nordic_route_offset integer DEFAULT 0,
ADD COLUMN nordic_route_colour text DEFAULT '',
ADD COLUMN nordic_route_length integer DEFAULT 1000000,
ADD COLUMN nordic_route_render_colour text DEFAULT '',
ADD COLUMN direction_to_route integer DEFAULT 0;

UPDATE osm_pistes_route_members
SET 
  nordic_route_offset = 0,
  nordic_route_colour = (SELECT nordic_route_colour
                            FROM osm_pistes_routes 
                            WHERE osm_pistes_routes.osm_id=osm_pistes_route_members.osm_id),
  nordic_route_render_colour = (SELECT nordic_route_render_colour
                            FROM osm_pistes_routes 
                            WHERE osm_pistes_routes.osm_id=osm_pistes_route_members.osm_id),
  direction_to_route = (SELECT 
                          CASE WHEN
                            ST_IsEmpty(
                              ST_GeometryN(
                                ST_SharedPaths(pistes_routes.geometry,osm_pistes_route_members.geometry),
                                 1)
                            )
                            THEN -1
                            ELSE 1
                          END
                        FROM pistes_routes
                        WHERE pistes_routes.osm_id=osm_pistes_route_members.osm_id
                        AND ST_GeometryType(osm_pistes_route_members.geometry) in ('ST_MultiLineString', 'ST_LineString')
                        AND ST_GeometryType(pistes_routes.geometry) in ('ST_MultiLineString', 'ST_LineString')
                            ),
  nordic_route_length=(SELECT ST_Length(pistes_routes.geometry) 
                            FROM pistes_routes
                            WHERE pistes_routes.osm_id=osm_pistes_route_members.osm_id);



 -- ~ Some members are similar but their names: just the smallest route label is worth rendering
ALTER TABLE osm_pistes_route_members ADD COLUMN worth_rendering boolean default true;
  -- ~ Count number of colors by member
ALTER TABLE osm_pistes_route_members ADD COLUMN routes_cnt integer DEFAULT 0;
 -- ~ Max route length by color by member
ALTER TABLE osm_pistes_route_members ADD COLUMN longest_route_length integer DEFAULT 0; 
 -- ~ Min route length by color by member
ALTER TABLE osm_pistes_route_members ADD COLUMN shortest_route_length integer DEFAULT 0; 
  -- ~ Rank over longest route length by color by member not workin as expected
ALTER TABLE osm_pistes_route_members ADD COLUMN member_offset_rank integer DEFAULT 0;
 -- ~ Logical offset exple: -1.5, -0.5, +0.5, +1.5 
ALTER TABLE osm_pistes_route_members ADD COLUMN member_offset real DEFAULT 0.0;
  -- ~ Harmonize direction_to_offset
 -- ~ Rationale: direction_to_route not perfect, direction to route gives the proper side, 
-- ~ but sometimes shared routes are of opposite directions.
-- ~ Rendering shortest route on top will mask it, but long route may be hidden at some places
-- ~ See GTJ - otherwise look for direction to smallest route
ALTER TABLE osm_pistes_route_members ADD COLUMN direction_to_offset integer DEFAULT 1; 
-- ~check the direction to offset for the complete route be smaller
-- ~ to helps short loops being offset toward interior
ALTER TABLE pistes_routes ADD COLUMN direction_to_shorter_offset integer DEFAULT 1;
ALTER TABLE osm_pistes_route_members ADD COLUMN direction_to_shorter_offset integer DEFAULT 1;

 -- ~ Count number of colors by member
UPDATE osm_pistes_route_members
SET routes_cnt = tmp.count
FROM (SELECT member,
	 count(DISTINCT nordic_route_render_colour) AS count
	FROM osm_pistes_route_members
	WHERE nordic_route_render_colour <>''
	GROUP BY member) AS tmp
WHERE osm_pistes_route_members.member = tmp.member
AND osm_pistes_route_members.nordic_route_render_colour <>''; 

-- ~ SELECT 
	 -- ~ distinct nordic_route_render_colour
	-- ~ FROM osm_pistes_route_members
	-- ~ WHERE nordic_route_render_colour <>''
	-- ~ AND member=379332836;

 -- ~ Max route length by color by member
UPDATE osm_pistes_route_members SET longest_route_length=0;
 
UPDATE osm_pistes_route_members SET longest_route_length = tmp.len
	FROM ( SELECT id,
				MAX (nordic_route_length) OVER (
				 PARTITION BY nordic_route_render_colour, member
				 ) len
		FROM osm_pistes_route_members
		 WHERE nordic_route_render_colour <> ''
	) tmp
 WHERE 
 osm_pistes_route_members.id = tmp.id;
 
 -- ~ Min route length by color by member
UPDATE osm_pistes_route_members SET shortest_route_length=0;
 
UPDATE osm_pistes_route_members SET shortest_route_length = tmp.len
	FROM ( SELECT id,
				MIN (nordic_route_length) OVER (
				 PARTITION BY nordic_route_render_colour, member
				 ) len
		FROM osm_pistes_route_members
		 WHERE nordic_route_render_colour <> ''
	) tmp
 WHERE 
 osm_pistes_route_members.id = tmp.id;
 
 -- ~ Rank over longest route length by color by member 
UPDATE osm_pistes_route_members SET member_offset_rank=0;

UPDATE osm_pistes_route_members SET member_offset_rank = tmp.rnk
FROM ( SELECT  id, 
				DENSE_RANK() OVER (
				 PARTITION BY member
				 ORDER BY longest_route_length 
				 ) rnk
		FROM osm_pistes_route_members
		 WHERE nordic_route_render_colour <> ''
		 
	) tmp
 WHERE osm_pistes_route_members.id = tmp.id;
 
UPDATE osm_pistes_route_members SET member_offset_rank= 3 WHERE member_offset_rank > 3;
-- ~ Some members are similar but their names: just the smallest route label is worth rendering
UPDATE osm_pistes_route_members SET worth_rendering=true;

-- ~ Document grouping queries:
-- ~ SELECT array_agg(member), count(member), (piste_type, grooming, difficulty, oneway, lit1, lit2, nordic_route_render_colour), array_agg(id) FROM osm_pistes_route_members
-- ~ GROUP BY member, piste_type, grooming, difficulty, oneway, lit1, lit2, nordic_route_render_colour;
 -- ~ {31485063}                                               |     1 | (nordic,classic;skating,"",1,f,t,#f1ae4c)           | {18123}
 -- ~ {31485063}                                               |     1 | (nordic,classic;skating,"",1,f,t,#f1e24c)           | {18100}
 -- ~ {32063942,32063942}                                      |     2 | (nordic,classic;skate,"",0,f,t,#4c4c4c)             | {70256,70403}
 -- ~ {32063942}                                               |     1 | (nordic,classic;skate,"",0,f,t,#4ce44c)             | {70305}
 -- ~ {32063942}                                               |     1 | (nordic,classic;skate,"",0,f,t,#6d6a6e)             | {70344}
-- ~ SELECT cnt, data, ids FROM 
	-- ~ (SELECT array_agg(member) as members,
			-- ~ array_agg(id) as ids,
			-- ~ count(member) as cnt,
			-- ~ (member, piste_type, grooming, difficulty, oneway, lit1, lit2, nordic_route_render_colour) as data FROM osm_pistes_route_members
	-- ~ GROUP BY member, piste_type, grooming, difficulty, oneway, lit1, lit2, nordic_route_render_colour) as sq
-- ~ WHERE cnt >1;
 -- ~ cnt  |                              data                              
-- ~ ------+----------------------------------------------------------------
    -- ~ 3 | (921089469,nordic,"","",0,f,t,"")
    -- ~ 2 | (47663883,nordic,classic,intermediate,0,f,f,"")
    -- ~ 2 | (29223440,nordic,classic+skating,easy,0,f,f,"")
    -- ~ 3 | (156796308,nordic,classic+skating,novice,1,t,f,#4c4c4c)
    -- ~ 2 | (3268274648,nordic,"","",0,f,f,"")
    -- ~ 3 | (238548718,nordic,classic,easy,0,f,f,"")

-- ~ do
-- ~ $$
-- ~ declare
    -- ~ current_member record;
    -- ~ m record;
    -- ~ query text;
    -- ~ var int;
-- ~ begin
    -- ~ for current_member in 
		-- ~ SELECT cnt, data, ids FROM 
			-- ~ (SELECT array_agg(member) as members,
				-- ~ array_agg(id) as ids,
				-- ~ count(member) as cnt,
				-- ~ (member, piste_type, grooming, difficulty, oneway, lit1, lit2, nordic_route_render_colour) as data FROM osm_pistes_route_members
				-- ~ GROUP BY member, piste_type, grooming, difficulty, oneway, lit1, lit2, nordic_route_render_colour) as sq
		-- ~ WHERE cnt >1
	-- ~ LOOP
		-- ~ foreach var in array current_member.ids
		-- ~ LOOP
			-- ~ UPDATE osm_pistes_route_members SET worth_rendering=
				-- ~ CASE WHEN
					-- ~ nordic_route_length = shortest_route_length
					-- ~ AND nordic_route_render_colour <>''
					-- ~ THEN true
					-- ~ ELSE false
				-- ~ END
			-- ~ WHERE id=var;
		-- ~ end loop;
    -- ~ end loop;
-- ~ end;
-- ~ $$;
-- ~ A bit faster :
UPDATE osm_pistes_route_members SET worth_rendering=true;
WITH cte as (
		SELECT cnt, data, ids, members FROM 
			(SELECT array_agg(member) as members,
				array_agg(id) as ids,
				count(member) as cnt,
				(member, piste_type, grooming, difficulty, oneway, lit1, lit2, nordic_route_render_colour) as data FROM osm_pistes_route_members
				WHERE nordic_route_render_colour <> ''
				GROUP BY member, piste_type, grooming, difficulty, oneway, lit1, lit2, nordic_route_render_colour) as sq
		WHERE cnt >1
)
UPDATE osm_pistes_route_members SET worth_rendering = false
FROM cte
WHERE nordic_route_length <> shortest_route_length
AND nordic_route_render_colour <>'' -- ~ they won't have a cnt otherwise
AND osm_pistes_route_members.id = ANY (cte.ids);

-- ~set worth rendering = false when nordic_route_render_colour = '' and other member with nordic_route_render_colour <> ''
--~Otherwise, we have issues here: http://127.0.0.1:6789/pistes-carto/#18/47.53764/12.39976
WITH cte AS (SELECT 
	distinct member
	FROM osm_pistes_route_members
	WHERE nordic_route_render_colour <> '')
UPDATE osm_pistes_route_members SET worth_rendering = false
FROM cte
WHERE osm_pistes_route_members.member = cte.member
AND osm_pistes_route_members.nordic_route_render_colour = '';

-- ~ Compute edge logical offset (for instance -1.5, -0.5, +0.5, +1.5)
UPDATE osm_pistes_route_members SET member_offset =0;

UPDATE osm_pistes_route_members
SET member_offset = (
CASE WHEN routes_cnt <5
	THEN
	 -(member_offset_rank*1.0 - 1 - (routes_cnt*1.0 - 1.0)/2.0) 
	ELSE
	 -(member_offset_rank*1.0 - 1 - (4*1.0 - 1.0)/2.0) 
END)
WHERE routes_cnt >1;

-- ~check the direction to offset for the complete route be smaller
-- ~ to helps short loops being offset toward interior - 
-- ~ Is it worth it? it seems to works automagically, maybe a property
 -- ~ of st_linemerge / direction_to_route or st_OfsetCurve
UPDATE pistes_routes SET direction_to_shorter_offset=1;

UPDATE pistes_routes SET direction_to_shorter_offset=(
	  CASE WHEN
		  ST_Length( ST_OffsetCurve(pistes_routes.geometry,10) ) < 
			 ST_Length( pistes_routes.geometry )
		THEN -1
		ELSE 1
	  END
	)
	WHERE ST_GeometryType(pistes_routes.geometry) in ('ST_MultiLineString', 'ST_LineString');

WITH cte AS (SELECT 
	  osm_id,
	  direction_to_shorter_offset
	FROM pistes_routes)
UPDATE osm_pistes_route_members SET direction_to_shorter_offset=cte.direction_to_shorter_offset
FROM cte
WHERE osm_pistes_route_members.osm_id = cte.osm_id;

 -- ~ Harmonize direction_to_offset
 -- ~ Rationale: direction_to_route not perfect, direction to route gives the proper side, 
-- ~ but sometimes shared routes are of opposite directions.
-- ~ Rendering shortest route on top will mask it, but long route may be hidden at some places
-- ~ See GTJ - otherwise look for direction to smallest route

UPDATE osm_pistes_route_members SET direction_to_offset=direction_to_route;

UPDATE osm_pistes_route_members SET direction_to_offset = tmp.dir
	FROM ( SELECT member, id, 
				CASE 
					WHEN AVG(direction_to_route*direction_to_shorter_offset) FILTER (WHERE member_offset_rank <3) OVER ( PARTITION BY member) < 0 THEN -1
					WHEN AVG(direction_to_route*direction_to_shorter_offset) FILTER (WHERE member_offset_rank <3)OVER ( PARTITION BY member) > 0 THEN 1
					-- ~ FILTER limits the number of routes to the shortest ones to avoid too many flip-flaps when unavoidable
					ELSE 1
				END as dir
		FROM osm_pistes_route_members
		WHERE routes_cnt > 1  
	) tmp
 WHERE 
 osm_pistes_route_members.id = tmp.id;
 
