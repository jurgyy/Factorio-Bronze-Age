local util = require("ba-util")

local road_network = require("script/path-network")

--local road_tile_list_name = "road-tile-list"
local road_tiles = {
    ["ba-path"] = true
}

---@return table<string, boolean>
local get_road_tiles = function()
    if road_tiles then return road_tiles end
    error("oops")
    -- road_tiles = {}
    -- local tile_list_item = game.item_prototypes[road_tile_list_name]
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
    for k, tile in pairs (event.tiles) do
        local position = tile.position
        road_network.add_node(event.surface_index, position.x, position.y)
    end
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

---@param event EventData.on_player_mined_tile|EventData.on_robot_mined_tile
local on_mined_tile = function(event)
    local tiles = event.tiles
    local new_tiles = {}
    local refund_count = 0
    for k, tile in pairs (tiles) do
        if is_road_tile(tile.old_tile.name) then
            if road_network.remove_node(event.surface_index, tile.position.x, tile.position.y) then
                --can't remove this tile, supply or requester is there.
                new_tiles[k] = {name = tile.old_tile.name, position = tile.position}
                refund_count = refund_count + 1
            end
        end
    end

    if next(new_tiles) then
        local surface = game.get_surface(event.surface_index) --[[@as LuaSurface]]
        surface.set_tiles(new_tiles)
    end

    if refund_count > 0 then
        if event.player_index then
            local player = game.get_player(event.player_index)
            if player then
                player.remove_item({name = "road", count = refund_count})
            end
        end
        local robot = event.robot
        if robot then
            robot.get_inventory(defines.inventory.robot_cargo).remove({name = "road", count = refund_count})
        end
    end
end

---@param event EventData.script_raised_set_tiles
local script_raised_set_tiles = function(event)
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