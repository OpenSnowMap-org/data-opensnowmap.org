echo "select distinct round(st_x(dp)::numeric,1), round(st_y(dp)::numeric,1)
    from (
        select (st_dumppoints(st_transform(way2,4326))).geom as dp 
            from (
                select ST_Startpoint(way) as way2
                from planet_osm_line
                where color is not null or colour is not null
            ) as foo 
        )as bar;" | psql -d pistes-mapnik > points.lst
