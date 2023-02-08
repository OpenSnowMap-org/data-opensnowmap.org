-- ~ #~ createuser osmuser
-- ~ #~ createdb --encoding=UTF8 --owner=osmuser pistes_osm2pgsql
-- ~ #~ psql pistes_osm2pgsql --command='CREATE EXTENSION postgis;'
-- ~ #~ psql pistes_osm2pgsql --command='CREATE EXTENSION hstore;'
-- ~ #~ psql pistes_osm2pgsql --command='CREATE EXTENSION pgrouting;'


-- ~ #~ /home/yves/DEV/osm2pgsql/build/osm2pgsql --create planet_pistes.osm.gz --database=pistes_osm2pgsql --output=flex --style=opensnowmap.lua 
-- ~ #~ --log-level=debug --log-sql-data
DROP TABLE IF EXISTS lines_noded;
DROP TABLE IF EXISTS lines_noded_vertices_pgr;
SET client_min_messages TO WARNING; -- ~ Otherwise we get a lot of 
-- ~ NOTICE:  WARNING: UPDATE public.lines_noded SET source = <NULL>, target = <NULL> WHERE id = xxxxx 
SELECT pgr_nodeNetwork('lines', 0.00000001, 'osm_id', 'geom');
-- ~ Necessary if we won't to route trough all intersection where ways aren't split
-- ~ "source", "target" and "id" column added automatically
-- ~ tolerance must be kept lower than initial resolution -> 0.00000001,
 -- ~ otherwise we may have trouble later with st_linemerge
-- ~ Build topology by chunks
-- ~ 0.00001 = 1m at equator
SELECT pgr_createTopology('lines_noded', 0.00000001, 'geom', 'id',rows_where:='id>=0 and id<50000',clean:=false);
SELECT pgr_createTopology('lines_noded', 0.00000001, 'geom', 'id',rows_where:='id>=50000 and id<100000',clean:=false);
SELECT pgr_createTopology('lines_noded', 0.00000001, 'geom', 'id',rows_where:='id>=100000 and id<150000',clean:=false);
SELECT pgr_createTopology('lines_noded', 0.00000001, 'geom', 'id',rows_where:='id>=150000 and id<200000',clean:=false);
SELECT pgr_createTopology('lines_noded', 0.00000001, 'geom', 'id',rows_where:='id>=200000 and id<250000',clean:=false);
SELECT pgr_createTopology('lines_noded', 0.00000001, 'geom', 'id',rows_where:='id>=250000 and id<300000',clean:=false);
SELECT pgr_createTopology('lines_noded', 0.00000001, 'geom', 'id',rows_where:='id>=300000 and id<350000',clean:=false);
SELECT pgr_createTopology('lines_noded', 0.00000001, 'geom', 'id',rows_where:='id>=350000 and id<400000',clean:=false);
SELECT pgr_createTopology('lines_noded', 0.00000001, 'geom', 'id',rows_where:='id>=400000 and id<450000',clean:=false);
SELECT pgr_createTopology('lines_noded', 0.00000001, 'geom', 'id',rows_where:='id>=450000 and id<500000',clean:=false);
SELECT pgr_createTopology('lines_noded', 0.00000001, 'geom', 'id',rows_where:='id>=500000 and id<550000',clean:=false);
SELECT pgr_createTopology('lines_noded', 0.00000001, 'geom', 'id',rows_where:='id>=550000 and id<600000',clean:=false);
SELECT pgr_createTopology('lines_noded', 0.00000001, 'geom', 'id',rows_where:='id>=600000 and id<650000',clean:=false);
SELECT pgr_createTopology('lines_noded', 0.00000001, 'geom', 'id',rows_where:='id>=650000',clean:=false);
-- ~ The following could be used (faster?) from newer pgrouting versions
-- ~ DROP TABLE  IF EXISTS lines_noded_vertices_pgr;
-- ~ SELECT  * INTO lines_noded_vertices_pgr
-- ~ FROM pgr_extractVertices('SELECT id, the_geom AS geom FROM lines_noded');

-- ~ WITH
    -- ~ out_going AS (
        -- ~ SELECT id AS vid, unnest(out_edges) AS eid, x, y
        -- ~ FROM lines_noded_vertices_pgr
    -- ~ )
-- ~ UPDATE lines_noded
-- ~ SET source = vid, x1 = x, y1 = y
-- ~ FROM out_going WHERE id = eid;

-- ~ WITH
    -- ~ in_coming AS (
        -- ~ SELECT id AS vid, unnest(in_edges) AS eid, x, y
        -- ~ FROM lines_noded_vertices_pgr
    -- ~ )
-- ~ UPDATE lines_noded
-- ~ SET target = vid, x2 = x, y2 = y
-- ~ FROM in_coming WHERE id = eid;

-- ~ Set default cost
ALTER TABLE lines_noded ADD COLUMN cost float;
ALTER TABLE lines_noded ADD COLUMN reverse_cost float;
ALTER TABLE lines_noded ADD COLUMN length_m float;
UPDATE lines_noded SET length_m = ST_LengthSpheroid(geom, 'SPHEROID["GRS_1980",6378137,298.257222101]' );
UPDATE lines_noded SET cost = length_m;
UPDATE lines_noded SET reverse_cost = cost;

-- ~ copy columns relevant for routing from lines into the noded table
ALTER TABLE lines_noded ADD COLUMN oneway text;
ALTER TABLE lines_noded ADD COLUMN piste_type text;
ALTER TABLE lines_noded ADD COLUMN lift_type text;
ALTER TABLE lines_noded ADD COLUMN relation_piste_type text;
ALTER TABLE lines_noded ADD COLUMN tags jsonb;

UPDATE lines_noded
SET oneway=lines.oneway,
piste_type=lines.piste_type,
lift_type=lines.lift_type,
relation_piste_type=lines.relation_piste_type,
tags=lines.tags
FROM lines
WHERE lines.osm_id=lines_noded.old_id;

ALTER TABLE lines_noded ADD COLUMN access text;
UPDATE lines_noded
SET access=lines.tags->>'access'
FROM lines
WHERE lines.osm_id=lines_noded.old_id;

-- ~ # lifts :
-- ~ # Default oneway lifts:
UPDATE lines_noded SET reverse_cost = -1 
WHERE piste_type is null
AND lift_type IN ('chair_lift', 'drag_lift', 'platter', 't-bar','j-bar', 'magic_carpet', 'rope_tow', 'mixed_lift')
AND (oneway is null OR oneway NOT IN ('no','-1','reversible'));

-- ~ # When specified:
UPDATE lines_noded SET cost = -1 
WHERE piste_type is null
AND  lift_type IN ('chair_lift', 'drag_lift', 'platter', 't-bar','j-bar', 'magic_carpet', 'rope_tow', 'mixed_lift')
AND oneway IN ('-1');

UPDATE lines_noded SET reverse_cost = -1 
WHERE piste_type is null
AND lift_type <> ''
AND lift_type NOT IN ('chair_lift', 'drag_lift', 'platter', 't-bar','j-bar', 'magic_carpet', 'rope_tow', 'mixed_lift')
AND oneway IN ('yes');

UPDATE lines_noded SET cost = -1 
WHERE piste_type is null
AND lift_type <> ''
AND lift_type NOT IN ('chair_lift', 'drag_lift', 'platter', 't-bar','j-bar', 'magic_carpet', 'rope_tow', 'mixed_lift')
AND oneway IN ('-1');


UPDATE lines_noded SET cost = -1
WHERE piste_type is null
AND lift_type <> ''
AND access IN ('no','discouraged');

-- ~ Smallest costs set first, so that priority is given to strongest cost
-- ~ Relations cost set before way, so ways get final say
-- ~ # Downhill default:
UPDATE lines_noded SET reverse_cost = 500 * length_m 
WHERE  
  (relation_piste_type LIKE '%downhill%'
  OR relation_piste_type LIKE '%sled%'
  OR relation_piste_type LIKE '%ski_jump%'
  OR relation_piste_type LIKE '%snow_park%')
AND (oneway is null OR oneway NOT IN ('no','-1','reversible'));

UPDATE lines_noded SET cost = 500 * length_m 
WHERE  
  (relation_piste_type LIKE '%downhill%'
  OR relation_piste_type LIKE '%sled%'
  OR relation_piste_type LIKE '%ski_jump%'
  OR relation_piste_type LIKE '%snow_park%')
AND oneway IN ('-1');

-- ~ # rest When specified
UPDATE lines_noded SET reverse_cost = -1
WHERE  
  (relation_piste_type LIKE '%nordic%'
  OR relation_piste_type LIKE '%connection%'
  OR relation_piste_type LIKE '%hike%'
  OR relation_piste_type LIKE '%skitour%'
  OR relation_piste_type LIKE '%fatbike%'
  OR relation_piste_type LIKE '%sleigh%'
  OR relation_piste_type LIKE '%playground%'
  OR relation_piste_type LIKE '%ski_jump_landing%')
AND oneway IN ('yes');
UPDATE lines_noded SET cost = -1
WHERE  
  (relation_piste_type LIKE '%nordic%'
  OR relation_piste_type LIKE '%connection%'
  OR relation_piste_type LIKE '%hike%'
  OR relation_piste_type LIKE '%skitour%'
  OR relation_piste_type LIKE '%fatbike%'
  OR relation_piste_type LIKE '%sleigh%'
  OR relation_piste_type LIKE '%playground%'
  OR relation_piste_type LIKE '%ski_jump_landing%')
AND oneway IN ('-1');

-- ~ # Downhill default:
UPDATE lines_noded SET reverse_cost = 500 * length_m 
WHERE 
  (piste_type LIKE '%downhill%'
  OR piste_type LIKE '%sled%'
  OR piste_type LIKE '%ski_jump%'
  OR piste_type LIKE '%snow_park%')
AND (oneway is null OR oneway NOT IN ('no','-1','reversible'));

UPDATE lines_noded SET cost = 500 * length_m 
WHERE  
  (piste_type LIKE '%downhill%'
  OR piste_type LIKE '%sled%'
  OR piste_type LIKE '%ski_jump%'
  OR piste_type LIKE '%snow_park%')
AND oneway IN ('-1');


-- ~ # rest When specified

UPDATE lines_noded SET reverse_cost=-1
WHERE 
  (piste_type LIKE '%nordic%'
  OR piste_type LIKE '%connection%'
  OR piste_type LIKE '%hike%'
  OR piste_type LIKE '%skitour%'
  OR piste_type LIKE '%fatbike%'
  OR piste_type LIKE '%sleigh%'
  OR piste_type LIKE '%playground%'
  OR piste_type LIKE '%ski_jump_landing%')
AND oneway IN ('yes');

UPDATE lines_noded SET cost=-1
WHERE 
  (piste_type LIKE '%nordic%'
  OR piste_type LIKE '%connection%'
  OR piste_type LIKE '%hike%'
  OR piste_type LIKE '%skitour%'
  OR piste_type LIKE '%fatbike%'
  OR piste_type LIKE '%sleigh%'
  OR piste_type LIKE '%playground%'
  OR piste_type LIKE '%ski_jump_landing%')
AND oneway IN ('-1');

-- ~ Access tags

UPDATE lines_noded SET cost=-1, reverse_cost=-1
WHERE 
  (piste_type LIKE '%nordic%'
  OR piste_type LIKE '%downhill%'
  OR piste_type LIKE '%skitour%'
  OR piste_type LIKE '%ski_jump%'
  OR piste_type LIKE '%ski_jump_landing%'
  OR piste_type LIKE '%snow_park%'
  OR relation_piste_type LIKE '%nordic%'
  OR relation_piste_type LIKE '%downhill%'
  OR relation_piste_type LIKE '%skitour%'
  OR relation_piste_type LIKE '%ski_jump%'
  OR relation_piste_type LIKE '%ski_jump_landing%'
  OR relation_piste_type LIKE '%snow_park%')
AND (tags::json->>'ski'= 'no' or tags::json->>'ski'= 'discouraged');

UPDATE lines_noded SET cost=-1, reverse_cost=-1
WHERE 
  (piste_type LIKE '%connection%'
  OR piste_type LIKE '%hike%'
  OR relation_piste_type LIKE '%connection%'
  OR relation_piste_type LIKE '%hike%')
AND (tags::json->>'foot'= 'no' or tags::json->>'foot'= 'discouraged');

UPDATE lines_noded SET cost=-1, reverse_cost=-1
WHERE 
  (piste_type LIKE '%fatbike%'
  OR relation_piste_type LIKE '%fatbike%')
AND (tags::json->>'bicycle'= 'no' or tags::json->>'bicycle'= 'discouraged');

