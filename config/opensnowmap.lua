--~ Filtered in by osmium:
--~ piste:type
--~ aerialway
--~ railway=funicular
--~ railway=incline
--~ site=piste
--~ landuse=winter_sports
--~ sport=ski_jump
--~ sport=ski_jump_take_off
--~ man_made=snow_cannon
--~ sport=skating
--~ sport=ice_skating
--~ leisure=ice_rink
--~ sport=ice_stock
--~ sport=curling
--~ sport=ice_hockey
--~ route=piste
--~ route=ski

--~ lines (piste:type, aerialway, railway=funicular, incline) route_members, site members, sport
--~ areas
--~ points, sport, man_made=snow_cannon
--~ routes (type=route, route=piste || route=ski) with geometry, compare native with st_linemerge
--~ sites (landuse, site=piste relations) ?? geometry how-to ?
--~ relation_members cross table, see w2r

--~ # Add name_trgm -> post process
--~ # add route geometry
--~ # add convex_hull geometry for sites -> post process
--~ # add all piste:type as an array from way or relation into sites 
local srid = 4326
local tables = {}

tables.points = osm2pgsql.define_table({
    name='points', 
    ids = {type='any', type_column='type', id_column = 'osm_id'},
    columns = {
    { column = 'tags', type = 'jsonb' },
    { column = 'name', type = 'text' },
    { column = 'geom', type = 'point', projection = srid },
    { column = 'sites_ids',  sql_type = 'int8[]' }, -- array with integers (for relation IDs) populated at postprocess
    { column = 'landuses_ids',  sql_type = 'int8[]' }, -- array with integers (for relation IDs) populated at postprocess
    }
})

tables.lines = osm2pgsql.define_table({
    name='lines', 
    ids = {type='any', type_column='type', id_column = 'osm_id'},
    columns = {
    { column = 'tags', type = 'jsonb' },
    { column = 'name', type = 'text' },
    { column = 'oneway', type = 'text' },
    { column = 'piste_type', type = 'text' },
    { column = 'lift_type', type = 'text' },
    { column = 'relation_piste_type', type = 'text' },
    { column = 'geom', type = 'linestring', projection = srid },
    { column = 'routes_ids',  sql_type = 'int8[]' }, -- array with integers (for relation IDs)
    { column = 'sites_ids',  sql_type = 'int8[]' }, -- array with integers (for relation IDs) populated at postprocess
    { column = 'landuses_ids',  sql_type = 'int8[]' }, -- array with integers (for relation IDs) populated at postprocess
    }
})

tables.areas = osm2pgsql.define_table({
    name='areas', 
    ids = {type='any', type_column='type', id_column = 'osm_id'},
    columns = {
    { column = 'tags', type = 'jsonb' },
    { column = 'name', type = 'text' },
    { column = 'piste_type', type = 'text' },
    { column = 'relation_piste_type', type = 'text' },
    { column = 'geom', type = 'geometry', projection = srid },
    { column = 'area', type = 'area' },
    { column = 'routes_ids',  sql_type = 'int8[]' }, -- array with integers (for relation IDs)
    { column = 'sites_ids',  sql_type = 'int8[]' }, -- array with integers (for relation IDs) populated at postprocess
    { column = 'landuses_ids',  sql_type = 'int8[]' }, -- array with integers (for relation IDs) populated at postprocess
    }
})

tables.routes = osm2pgsql.define_table({
    name='routes', 
    ids = {type='any', type_column='type', id_column = 'osm_id'},
    columns = {
    { column = 'tags', type = 'jsonb' },
    { column = 'name', type = 'text' },
    { column = 'relation_piste_type', type = 'text' },
    { column = 'geom', type = 'multilinestring', projection = srid },
    { column = 'sites_ids',  sql_type = 'int8[]' }, -- array with integers (for relation IDs) populated at postprocess
    { column = 'landuses_ids',  sql_type = 'int8[]' }, -- array with integers (for relation IDs) populated at postprocess
    }
})

tables.sites = osm2pgsql.define_table({
     name ='sites', 
     ids = {type='any', type_column='type', id_column = 'osm_id'},
     columns = {
      { column = 'tags', type = 'jsonb' },
    { column = 'name', type = 'text' },
      { column = 'piste_type', type = 'text' }, -- populated at postprocess
      { column = 'lift_type', type = 'text' }, -- not used
      { column = 'site_type', type = 'text' }, -- either 'site' or 'landuse'
      { column = 'geom', type = 'geometry', projection = srid },
      { column = 'area', type = 'area' }
    }
})
-- table to join relation and member ids
tables.relations = osm2pgsql.define_table({
     name ='relations', 
     ids = {type='relation',id_column='relation_id'},
     columns = {
      { column = 'member_id', type = 'bigint' },
      { column = 'relation_type', type = 'text' }, -- 'site' 'route'
      { column = 'relation_piste_type', type = 'text' }, -- 'site' 'route'
      { column = 'member_type', type = 'text'} -- n, w, r
    }
})
-- This will be used to store information about relations queryable by member
-- way id. It is a table of tables. The outer table is indexed by the way id,
-- the inner table indexed by the relation id. This way even if the information
-- about a relation is added twice, it will be in there only once. It is
-- always good to write your osm2pgsql Lua code in an idempotent way, i.e.
-- it can be called any number of times and will lead to the same result.

-- As only way can be re-processed at stage 2, sites relations are handled in post-processing
local w2r = {}


function has_area_tags(tags)
    if tags.area == 'yes' 
      or tags.landuse == 'winter_sports'
    then
        return true
    end
end

function osm2pgsql.process_node(object)
    
    local name =''
    if object.tags['piste:name'] then
      name=object.tags['piste:name']
    else
      name=object.tags['name']
    end

    tables.points:add_row({
        tags = object.tags,
        name = name,
    })
end

function osm2pgsql.process_way(object)

    -- If there is any data from parent relations, add it in
    local d = w2r[object.id]
    local r_ids
    local r_types=''
    if d then
        local ids = {}
        local types = {}
        for rel_id, rel_type in pairs(d) do
            types[#types + 1] = rel_type
            ids[#ids + 1] = rel_id
        end
        table.sort(types)
        table.sort(ids)
        r_ids = '{' .. table.concat(ids, ',') .. '}'
        --~ r_types = table.concat(types, ';')
                -- As we can't deal with nested relation,this is better off in post-processing
                -- to avoid duplicates
    end
    
    local name =''
    if object.tags['piste:name'] then
      name=object.tags['piste:name']
    else
      name=object.tags['name']
    end

    if object.tags['piste:grooming'] == 'classic+skating' then
      object.tags['piste:grooming'] = 'classic;skating'
    end
    
    if object.is_closed and has_area_tags(object.tags) then
      if object.tags.landuse == 'winter_sports' then
        tables.sites:add_row({
            tags = object.tags,
            name= name,
            piste_type=object.tags['piste:type'],
            routes_ids = r_ids,
            relation_piste_type=r_types,
            site_type = 'landuse',
            geom = { create = 'line' }
            --~ Can't create areas - don't understand why
        })
      else
        tables.areas:add_row({
            tags = object.tags,
            name= name,
            piste_type=object.tags['piste:type'],
            routes_ids = r_ids,
            relation_piste_type=r_types,
            geom = { create = 'area' }
        })
      end
    else
        local lift = {}
        lift[#lift + 1] = object.tags['aerialway']
        lift[#lift + 1] = object.tags['railway']
        
        local onew
        if object.tags['piste:oneway'] then
          onew = object.tags['piste:oneway']
        else
          onew = object.tags.oneway
        end
        
        tables.lines:add_row({
            tags = object.tags,
            name= name,
            piste_type=object.tags['piste:type'],
            lift_type=table.concat(lift,';'),
            oneway=onew,
            routes_ids = r_ids,
            relation_piste_type=r_types
        })
    end
end

-- This function is called for every added, modified, or deleted relation.
-- Its only job is to return the ids of all member ways of the specified
-- relation we want to see in stage 2 again. It MUST NOT store any information
-- about the relation!
function osm2pgsql.select_relation_members(relation)
    -- Only interested in relations with type=route
    if relation.tags.type == 'route' then
        return { ways = osm2pgsql.way_member_ids(relation) }
    end
end

function osm2pgsql.process_relation(object)
    -- keep relationship informationin relations table
    for _, member in ipairs(object.members) do
        tables.relations:add_row({
            member_type = member.type,
            member_id = member.ref,
            relation_type = object.tags.type,
            relation_piste_type = object.tags['piste:type'] --to speed up post-process
        })
    
    end
    
    local name =''
    if object.tags['piste:name'] then
      name=object.tags['piste:name']
    else
      name=object.tags['name']
    end
    
    if object.tags['piste:grooming'] == 'classic+skating' then
      object.tags['piste:grooming'] = 'classic;skating'
    end

    local type = object.tags.type

    if type == 'route' then
        tables.routes:add_row({
            tags = object.tags,
            name = name,
            relation_piste_type=object.tags['piste:type'],
            geom = { create = 'line' }
        })
        -- Go through all the members and store relation ids and 'piste:type' so they
        -- can be found by the way id.
        for _, member in ipairs(object.members) do
            if member.type == 'w' then
                if not w2r[member.ref] then
                    w2r[member.ref] = {}
                end
                w2r[member.ref][object.id] = object.tags['piste:type']
                -- As we can't deal with nested relation,this is better off in post-processing
                -- to avoid duplicates
            end
        end
        
        return
    end

    if type == 'site' then
        tables.sites:add_row({
            tags = object.tags,
            name = name,
            site_type = 'site',
            geom = { create = 'line' }
        })
        return
    end

    if type == 'multipolygon' then
      if object.tags.landuse == 'winter_sports' then
          tables.sites:add_row({
              tags = object.tags,
              name = name,
              site_type = 'landuse',
              geom = { create = 'area' }
          })
      else
        tables.areas:add_row({
            tags = object.tags,
            name = name,
            piste_type=object.tags['piste:type'],
            geom = { create = 'area' }
        })
        -- exple https://www.openstreetmap.org/relation/2998695 
      end
    end
end
