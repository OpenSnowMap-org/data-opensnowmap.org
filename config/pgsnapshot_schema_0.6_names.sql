
--~ select name_trgm from relations where name_trgm % 'matthiez sarazin' ORDER BY name_trgm;

-- Add a postgis GEOMETRY column to the way table for the purpose of storing the full linestring of the way.
ALTER TABLE ways ADD name_trgm text;
ALTER TABLE relations ADD name_trgm text;

--~ -- Add an index to the bbox column.
CREATE INDEX idx_name_ways_trgm ON ways USING gin(name_trgm gin_trgm_ops);
CREATE INDEX idx_name_relations_trgm ON relations USING gin(name_trgm gin_trgm_ops);


-- Add a function to update relation geometries: a polygon for sites, a multilinestring for routes.
CREATE OR REPLACE FUNCTION insertName() RETURNS trigger AS $$ 
BEGIN
	UPDATE ways SET name_trgm =
	     coalesce(tags->'piste:name',tags->'name','');
	UPDATE relations SET name_trgm =
	     coalesce(tags->'piste:name',tags->'name','');
	RETURN NEW;
END;
$$ LANGUAGE PLPGSQL;

-- Add a function to update relation geometries: a polygon for sites, a multilinestring for routes.
CREATE OR REPLACE FUNCTION updateWayName() RETURNS trigger AS $$ 
BEGIN
	UPDATE ways SET name_trgm =
	     coalesce(tags->'piste:name',tags->'name','')
	WHERE id=OLD.id;
	RETURN NEW;
END;
$$ LANGUAGE PLPGSQL;

CREATE OR REPLACE FUNCTION updateRelName() RETURNS trigger AS $$ 
BEGIN
	UPDATE relations SET name_trgm =
	     coalesce(tags->'piste:name',tags->'name','')
	WHERE id=OLD.id;
	RETURN NEW;
END;
$$ LANGUAGE PLPGSQL;

-- Create a trigger to update ALL the relation geometry at import, only at the end of import
CREATE TRIGGER ways_insert
AFTER INSERT ON ways
FOR EACH STATEMENT -- Once every sql, not once every changed row
EXECUTE PROCEDURE insertName();
CREATE TRIGGER rels_insert
AFTER INSERT ON relations
FOR EACH STATEMENT -- Once every sql, not once every changed row
EXECUTE PROCEDURE insertName();

-- Create a trigger to update the SINGLE relation geometry at update, for each row updated
CREATE TRIGGER ways_update
AFTER UPDATE OF tags ON ways
FOR EACH ROW -- once every changed row
EXECUTE PROCEDURE updateWayName();
CREATE TRIGGER rels_update
AFTER UPDATE OF tags ON relations
FOR EACH ROW -- once every changed row
EXECUTE PROCEDURE updateRelName();
