
-- Add a function to update relation geometries: a polygon for sites, a multilinestring for routes.
CREATE OR REPLACE FUNCTION insertRelationType() RETURNS trigger AS $$ 
BEGIN
	UPDATE relations 
	SET tags = tags ||hstore('piste:type',(
		SELECT string_agg(trim('()' from types::text),';') from
			(SELECT distinct tags->'piste:type' FROM ways
			WHERE ways.id in (
					SELECT member_id FROM relation_members WHERE relation_id = relations.id
					)
			ORDER BY tags->'piste:type'
			) as types)
		)
	WHERE tags->'site' = 'piste'; --all relations at import
	
	RETURN NEW;
END;
$$ LANGUAGE PLPGSQL;

-- Add a function to update relation geometries: a polygon for sites, a multilinestring for routes.
CREATE OR REPLACE FUNCTION updateRelationType() RETURNS trigger AS $$ 
BEGIN
	UPDATE relations 
	SET tags = tags ||hstore('piste:type',(
		SELECT string_agg(trim('()' from types::text),';') from
			(SELECT distinct tags->'piste:type' FROM ways
			WHERE ways.id in (
					SELECT member_id FROM relation_members WHERE relation_id = relations.id
					)
			ORDER BY tags->'piste:type'
			) as types)
		)
	WHERE tags->'site' = 'piste' and id=OLD.relation_id; --only the changed relation (OLD)

	RETURN NEW;
END;
$$ LANGUAGE PLPGSQL;
-- Create a trigger to update ALL the relation geometry at import, only at the end of import
CREATE TRIGGER rels_type_insert
AFTER INSERT ON relation_members
FOR EACH STATEMENT -- Once every sql, not once every changed row
EXECUTE PROCEDURE insertRelationType();
-- Create a trigger to update the SINGLE relation geometry at update, for each row updated
CREATE TRIGGER rels_type_update
AFTER UPDATE OF member_id OR DELETE ON relation_members
FOR EACH ROW -- once every changed row
EXECUTE PROCEDURE updateRelationType();



