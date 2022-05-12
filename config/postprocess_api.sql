CREATE UNIQUE INDEX idx_lines_osm_id ON lines(osm_id);
CREATE UNIQUE INDEX idx_points_osm_id ON points(osm_id);
CREATE UNIQUE INDEX idx_areas_osm_id ON areas(osm_id);
CREATE UNIQUE INDEX idx_routes_osm_id ON routes(osm_id);
CREATE UNIQUE INDEX idx_sites_osm_id ON sites(osm_id);
CREATE INDEX idx_member_id ON relations(member_id);
CREATE INDEX idx_relation_id ON relations(relation_id);


CREATE INDEX idx_name_lines_trgm ON lines USING gin(name gin_trgm_ops);
CREATE INDEX idx_name_areas_trgm ON areas USING gin(name gin_trgm_ops);
CREATE INDEX idx_routes_lines_trgm ON routes USING gin(name gin_trgm_ops);
CREATE INDEX idx_sites_lines_trgm ON sites USING gin(name gin_trgm_ops);
