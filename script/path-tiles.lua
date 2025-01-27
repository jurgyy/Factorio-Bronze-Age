local util = require("ba-util")
local condense_graph = require("shared/condense-graph")

local road_network = require("script/path-network")
local camps = require("script/camp")
local compounds = require("script/worker-compounds")
local worker_distribution = require("script/worker-distribution")
local housing_defines = require("shared/housing-defines")
local housing = require("script/housing")

--local road_tile_list_name = "road-tile-list"
local path_tile_names = {"ba-path"}

local road_tiles = {}
for _, name in pairs(path_tile_names) do
    road_tiles[name] = true
end

---@return table<string, boolean>
local get_road_tiles = function()
    if road_tiles then return road_tiles end
    error("oops")
    -- road_tiles = {}
    -- local tile_list_item = prototypes.item[road_tile_list_name]
    -- for tile_name, prototype in pairs (tile_list_item.tile_filters) do
    --     road_tiles[tile_name] = true
    -- end
    -- --game.print(serpent.line(road_tiles))
    -- return road_tiles
end

---@param name string Tile name
---@return boolean
local is_road_tile = function(name)
    return get_road_tiles()[name]
end

---@param event EventData.on_player_built_tile|EventData.on_robot_built_tile
local raw_road_tile_built = function(event)
    local profiler = game.create_profiler()
    local min_x, min_y, max_x, max_y
    local network_id
    local accumulates = {}
    for k, tile in pairs (event.tiles) do
        local position = tile.position
        --game.surfaces[1].create_entity{name = "flying-text", position = {position.x + 0.5, position.y + 0.5}, text = tostring(k)}
        local node_accumulates
        network_id, node_accumulates = road_network.add_node(event.surface_index, position.x, position.y)

        for src, dest in pairs(node_accumulates) do
            accumulates[src] = dest
        end

        if not min_x or position.x < min_x then
            min_x = position.x
        end
        if not max_x or position.x < max_x then
            max_x = position.x
        end
        if not min_y or position.y < min_y then
            min_y = position.y
        end
        if not max_y or position.y < max_y then
            max_y = position.y
        end
    end

    accumulates = condense_graph(accumulates)
    for src, dest in pairs(accumulates) do
        worker_distribution.transfer_network(src, dest)
    end

    local added = false
    local surface = game.surfaces[event.surface_index]
    local entities = surface.find_entities{{min_x - 1, min_y - 1}, {max_x + 2, max_y + 2}}
    --util.highlight_bbox(surface, {{min_x - 1, min_y - 1}, {max_x + 2, max_y + 2}})
    for _, entity in pairs(entities) do
        if not entity.valid then goto continue end
        local unit_number = entity.unit_number
        if housing_defines[entity.name] then
            housing.add_to_network(entity, network_id)
            goto continue
        end
        if not unit_number then goto continue end

        local compound = compounds.get_compound(unit_number)
        if compound then
            if not compound.path_network_id then
                worker_distribution.add_building(compound, network_id)
                added = true
            end
            goto continue
        end
        local camp = camps.get_camp(unit_number)
        if camp then
            if not camp.path_network_id then
                worker_distribution.add_building(camp, network_id)
                added = true
            end
            goto continue
        end
        ::continue::
    end

    if added then
        worker_distribution.recalculate(network_id)
    end

    profiler.stop()
    util.print({"", "result - ", profiler})
end

---@param event EventData.on_player_built_tile|EventData.on_robot_built_tile
local non_road_tile_built = function(event)
    local tiles = event.tiles
    local new_tiles = {}
    local refund_count = 0
    for k, tile in pairs (tiles) do
        if road_network.remove_node(event.surface_index, tile.position.x, tile.position.y) then
            new_tiles[k] = {name = tile.old_tile.name, position = tile.position}
            refund_count = refund_count + 1
        end
    end

    if next(new_tiles) then
        local surface = game.get_surface(event.surface_index) --[[@as LuaSurface]]
        surface.set_tiles(new_tiles)
    end


    if event.item then
        if refund_count > 0 then
            if event.player_index then
                local player = game.get_player(event.player_index)
                if player then
                    player.insert({name = event.item.name, count = refund_count})
                    player.remove_item({name = "ba-item-path", count = refund_count})
                end
            end
            local robot = event.robot
            if robot then
                robot.get_inventory(defines.inventory.robot_cargo).insert({name = event.item.name, count = refund_count})
                robot.get_inventory(defines.inventory.robot_cargo).remove({name = "ba-item-path", count = refund_count})
            end
        end
    end
end

---@param event EventData.on_player_built_tile|EventData.on_robot_built_tile
local on_built_tile = function(event)
    if is_road_tile(event.tile.name) then
        raw_road_tile_built(event)
    else
        non_road_tile_built(event)
    end
end


---Get network id of a connected array of tiles
---@param surface LuaSurface
---@param path_tiles OldTileAndPosition[]
---@return integer? network_id Nil if the array doesn't contain path tiles
local function get_tiles_network_id(surface, path_tiles)
    for _, tile in pairs(path_tiles) do
        local node = road_network.get_node(surface.index, tile.position.x, tile.position.y)
        if node then
            return node.id
        end
    end
end

---Removes entities from its network around a removed tile if no other tiles are around the entity
---and sets it to another network id if any other tile is near the entity. Importantly it does not recalculate
---the networks. You should do that afterwards using the return values of this function.
---@param surface LuaSurface
---@param tile OldTileAndPosition The removed tile
---@param network_id integer Original network_id for the removed tile
---@param changed_networks table<integer, boolean> table t<network_id: true> to store which networks are modified (other than network_id). This function adds to it and returns it
---@return boolean removed_any Did the function remove any entity from its network
---@return table<integer, boolean> changed_networks 
local function handle_entities_around_removed_tile(surface, tile, network_id, changed_networks)
    local entities = surface.find_entities{
        {tile.position.x - 1, tile.position.y - 1},
        {tile.position.x + 2, tile.position.y + 2}
    }
    local removed_entity = false

    for _, entity in pairs(entities) do
        local unit_number = entity.unit_number
        if not unit_number then goto continue end

        local building = compounds.get_compound(unit_number) or camps.get_camp(unit_number)
        if building and building.path_network_id == network_id then
            local path_tiles = util.get_path_tiles_around_entity(surface, entity)
            if not next(path_tiles) then
                -- Building not next to other tiles, just remove it
                worker_distribution.remove_building(building, false)
                removed_entity = true
                goto continue
            end

            local other_id = get_tiles_network_id(surface, path_tiles)
            -- Building next to other tile of the same network, don't do anything
            if network_id == other_id then goto continue end
            
            worker_distribution.remove_building(building, false)
            removed_entity = true
            if other_id then
                -- Building next to tile of other network, add it to that network
                worker_distribution.add_building(building, other_id, false)
                changed_networks[other_id] = true
            end
        end
        ::continue::
    end

    return removed_entity, changed_networks
end


---@param event EventData.on_player_mined_tile|EventData.on_robot_mined_tile
local on_mined_tile = function(event)
    local tiles = event.tiles
    local surface = game.surfaces[event.surface_index]
    
    local network_id -- Assuming all tiles are in the same network
    local changed_networks = {}
    local removed_entity = false
    for _, tile in pairs (tiles) do
        if is_road_tile(tile.old_tile.name) then
            network_id = road_network.remove_node(event.surface_index, tile.position.x, tile.position.y)
            if network_id then
                removed_entity, changed_networks = handle_entities_around_removed_tile(surface, tile, network_id, changed_networks)
            end
        end
    end
    if removed_entity and network_id then
        worker_distribution.recalculate(network_id)
    end
    
    for id, _ in pairs(changed_networks) do
        worker_distribution.recalculate(id)
    end
end

---@param event EventData.script_raised_set_tiles
local script_raised_set_tiles = function(event)
    error("Not implemented")
    if not event.tiles then return end
    local new_tiles = {}

    for k, tile in pairs (event.tiles) do
        if is_road_tile(tile.name) then
            road_network.add_node(event.surface_index, tile.position.x, tile.position.y)
        elseif road_network.remove_node(event.surface_index, tile.position.x, tile.position.y) then
            --can't remove this tile, depot is here.
            new_tiles[k] = {name = "ba-path", position = tile.position}
        end
    end

    if next(new_tiles) then
        local surface = game.get_surface(event.surface_index) --[[@as LuaSurface]]
        surface.set_tiles(new_tiles)
    end

end

local lib = {}

lib.events =
{
    [defines.events.on_player_built_tile] = on_built_tile,
    [defines.events.on_robot_built_tile] = on_built_tile,

    [defines.events.on_player_mined_tile] = on_mined_tile,
    [defines.events.on_robot_mined_tile] = on_mined_tile,

    [defines.events.script_raised_set_tiles] = script_raised_set_tiles
}

---@param surface LuaSurface
---@param position MapPosition
---@param value integer?
---@param scale float?
---@param filled boolean?
local function highlight_tile(surface, position, value, scale, filled)
    local function f(x)
        return math.sin(10000000/x)
    end
    scale = scale or 1

    local color
    if value then
        color = {
            r = 128 + 127 * f(value),
            g = 128 + 127 * f(value + 1),
            b = 128 + 127 * f(value + 2),
            a = 255
        }
    else
        color = { r = 255, g = 0, b = 0, a = 255 }
    end

    util.highlight_position(
        surface,
        position,
        color,
        true,
        scale,
        filled
    )
end

lib.add_commands = function()
    commands.add_command("klonan-show", nil, function(event)
        for surface_id, surface_map in pairs(road_network.get_nodes()) do
            local surface = game.surfaces[surface_id]
            for x, x_map in pairs(surface_map) do
                for y, node in pairs(x_map) do
                    highlight_tile(surface, {x = x, y = y}, node.id)
                end
            end
        end
    end)

    commands.add_command("ba-show-tile-id", nil, function(event)
        for surface_id, surface_map in pairs(road_network.get_nodes()) do
            local surface = game.surfaces[surface_id]
            for x, x_map in pairs(surface_map) do
                for y, node in pairs(x_map) do
                    surface.create_entity{name = "still-text", position = {x + 0.33, y + 0.33}, text = node.id}
                end
            end
        end
    end)

    commands.add_command("klonan-test-connected", nil, function(event)
        ---@type LuaSurface
        local surface = game.players[event.player_index].surface
    
        local entities = surface.find_entities_filtered{name="wooden-chest", position=game.player.position, radius=100}
        if not entities or not entities[2] then
            util.print("not enough entities found")
            return
        end

        for i, entity in pairs(entities) do
            if i > 2 then break end
            highlight_tile(surface, entity.position)
        end

        local set1 = util.get_path_sets_around(surface, entities[1].bounding_box)
        local set2 = util.get_path_sets_around(surface, entities[2].bounding_box)

        local connected = false
        for _, pos1 in pairs(set1) do
            for _, pos2 in pairs(set2) do
                local id1 = road_network.get_node(surface.index, math.floor(pos1.x), math.floor(pos1.y)).id
                local id2 = road_network.get_node(surface.index, math.floor(pos2.x), math.floor(pos2.y)).id
                connected = connected or (id1 and id1 == id2)
                if connected then break end
            end
            if connected then break end
        end

        game.print("Connected: " .. tostring(connected))
    end)
end

return lib