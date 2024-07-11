local util = require("ba-util")

local ba_console_commands = require("script/console")
local disjointSet = require("disjointSet")

---@class PathsScriptData
---@field disjoint_sets table<SurfaceIndex, DisjointSet>
local script_data = {
    disjoint_sets = {}
}

local function tile_built_event(event)
    if event.tile.name ~= "ba-path" then
        return
    end

    for _, old_tile_and_position in ipairs(event.tiles) do
        local position = {x = math.floor(old_tile_and_position.position.x), y = math.floor(old_tile_and_position.position.y)}

        if not script_data.disjoint_sets[event.surface_index] then
            script_data.disjoint_sets[event.surface_index] = disjointSet.new()
        end
        script_data.disjoint_sets[event.surface_index]:add{position=position}
    end
    
    show_disjoint_tile_set{
        player_index = event.player_index,
        name = "script",
        tick = event.tick
    }
end

---Commands---

---@param data CustomCommandData
function show_pathfinding_tile_nearest_entity(data)
    local player = game.get_player(data.player_index)
    if not player then return end
    
    local entities = player.surface.find_entities_filtered{name="character", position=game.player.position, radius=4, invert=true}
    if not entities or not entities[1] then
        util.print("no entity found")
        return
    end

    local disjoint_tiles = util.get_path_sets_around(entities[1].surface, entities[1].bounding_box)

    for _, position in ipairs(disjoint_tiles) do
        util.highlight_radius(entities[1].surface, position, 0.2, {r = 0, b = 0, g = 1, a = 0.5})
    end
end

---@param surface LuaSurface
---@param position MapPosition
---@param parent DisjointSetIndex
local function highlight_tile(surface, position, parent)
    local function f(x)
        return math.sin(10000000/x)
    end

    local color
    if parent then
        color = {
            r = 128 + 127 * f(parent.x),
            g = 128 + 127 * f(parent.y),
            b = 128 + 127 * f(parent.x + parent.y),
            a = 255
        }
    else
        color = { r = 255, g = 0, b = 0, a = 255 }
    end

    util.highlight_position(
        surface,
        position,
        color,
        true
    )
end

--- Compresses every tile and then shows a color based on its parent
---@param data CustomCommandData
function show_disjoint_tile_set(data)


    local surface = game.players[data.player_index].surface
    local ds = script_data.disjoint_sets[surface.index]

    if ds then
        for x, parent_x in pairs(ds.parent) do
            for y, parent_xy in pairs(parent_x) do
                local position = {x = x, y = y}
                local parent = ds:find(position)
                if parent then
                    highlight_tile(surface, position, parent)
                end
            end
        end
    end
end

---Searches all surfaces for all path tiles and recalculates disjoint sets from those. Afterwards it calls the show_disjoint_tile_set to compress the disj
---@param data CustomCommandData?
function recalculate_disjoint_tiles(data)
    for _, surface in pairs(game.surfaces) do
        local ds = disjointSet.new()
         
        local path = surface.find_tiles_filtered{name="ba-path"}
        for _, tile in ipairs(path) do
            ds:add{tile=tile}
        end

        -- Compressing
        for x, parent_x in pairs(ds.parent) do
            for y, parent_xy in pairs(parent_x) do
                local parent = ds:find{x = x, y = y}

                if data and surface.index == game.players[data.player_index].surface.index and parent then
                    highlight_tile(surface, {x=x, y=y}, parent)
                end
            end
        end
        script_data.disjoint_sets[surface.index] = ds
    end
end

---@param data CustomCommandData
function test_two_tiles(data)
    
    local surface = game.players[data.player_index].surface
    
    local entities = surface.find_entities_filtered{name="wooden-chest", position=game.player.position, radius=100}
    if not entities or not entities[2] then
        util.print("no entity found")
        return
    end

    local set1 = util.get_path_sets_around(surface, entities[1].bounding_box)
    local set2 = util.get_path_sets_around(surface, entities[2].bounding_box)
    
    local ds = script_data.disjoint_sets[surface.index]


    local connected = false
    for _, pos1 in pairs(set1) do
        for _, pos2 in pairs(set2) do
            connected = connected or ds:isConnected(pos1, pos2)
        end
    end
    util.print(connected)

    -- Just for show:
    for _, pos1 in pairs(set1) do
        local parent = ds:find(ds:get_index(pos1))
        if not parent then error("no parent in disjoint set") end
        highlight_tile(surface, pos1, parent)
    end
    for _, pos2 in pairs(set2) do
        local parent = ds:find(ds:get_index(pos2))
        if not parent then error("no parent in disjoint set") end
        highlight_tile(surface, pos2, parent)
    end

    util.highlight_position(surface, entities[1].position, {r=1, g=0, b=0, a=0.5}, true)
    util.highlight_position(surface, entities[2].position, {r=1, g=0, b=0, a=0.5}, true)

end
---End commands--


local lib = {}

lib.events = {
    [defines.events.on_player_built_tile] = tile_built_event,
    [defines.events.on_robot_built_tile] = tile_built_event,
}

lib.on_init = function()
    global.paths = global.paths or script_data
end

lib.on_load = function()
    script_data = global.paths or script_data
end

lib.on_configuration_changed = function()
    if not global.paths then
        global.paths = script_data
    end
end

lib.add_commands = function()
    commands.add_command("ba-show-tile", nil, ba_console_commands.show_pathfinding_tile_nearest_entity)
    commands.add_command("ba-test-connected", nil, ba_console_commands.test_two_tiles)

    commands.add_command("ba-recalculate-disjoint-tiles", nil, ba_console_commands.recalculate_disjoint_tiles)
    commands.add_command("ba-show-disjoint-tiles", nil, ba_console_commands.show_disjoint_tile_set)
end

return lib