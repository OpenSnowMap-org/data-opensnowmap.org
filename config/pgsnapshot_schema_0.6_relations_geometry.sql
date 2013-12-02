
-- Add a postgis GEOMETRY column to the way table for the purpose of storing the full linestring of the way.
SELECT AddGeometryColumn('relations', 'geom', 4326, 'GEOMETRY', 2);

-- Add an index to the bbox column.
CREATE INDEX idx_ways_geom ON relations USING gist (geom);
-- Cluster table by geographical location.
CLUSTER relations USING idx_ways_geom;

-- Add a function to update relation geometries: a polygon for sites, a multilinestring for routes.
CREATE OR REPLACE FUNCTION insertRelationGeom() RETURNS trigger AS $$ 
BEGIN
	UPDATE relations 
	SET geom=(
		SELECT ST_Centroid(st_collect(ways.linestring)) FROM ways
		WHERE ways.id in (
				SELECT member_id FROM relation_members WHERE relation_id = relations.id
				)
		)
	WHERE tags->'site' = 'piste'; --all relations at import
	
	UPDATE relations 
	SET geom=(
		SELECT ST_LineMerge(ST_Collect(ways.linestring)) FROM ways
		WHERE ways.id in (
				SELECT member_id FROM relation_members WHERE relation_id = relations.id
				)
		)
	WHERE tags->'type' = 'route'; --all relations at import
	
	RETURN NEW;
END;
$$ LANGUAGE PLPGSQL;

-- Add a function to update relation geometries: a polygon for sites, a multilinestring for routes.
CREATE OR REPLACE FUNCTION updateRelationGeom() RETURNS trigger AS $$ 
BEGIN
	UPDATE relations 
	SET geom=(
		SELECT ST_Centroid(st_collect(ways.linestring)) FROM ways
		WHERE ways.id in (
				SELECT member_id FROM relation_members WHERE relation_id = relations.id
				)
		)
	WHERE tags->'site' = 'piste' and id=OLD.relation_id; --only the changed relation (OLD)
	
	UPDATE relations 
	SET geom=(
		SELECT ST_LineMerge(ST_Collect(ways.linestring)) FROM ways
		WHERE ways.id in (
				SELECT member_id FROM relation_members WHERE relation_id = relations.id
				)
		)
	WHERE tags->'type' = 'route' and id=OLD.relation_id; --only the changed relation (OLD)
	
	RETURN NEW;
END;
$$ LANGUAGE PLPGSQL;
-- Create a trigger to update ALL the relation geometry at import, only at the end of import
CREATE TRIGGER rels_geom_insert
AFTER INSERT ON relation_members
FOR EACH STATEMENT -- Once every sql, not once every changed row
EXECUTE PROCEDURE insertRelationGeom();
-- Create a trigger to update the SINGLE relation geometry at update, for each row updated
CREATE TRIGGER rels_geom_update
AFTER UPDATE OF member_id OR DELETE ON relation_members
FOR EACH ROW -- once every changed row
EXECUTE PROCEDURE updateRelationGeom();

