local disjointSet     = require("disjointSet")
local util = require("ba-util")


local console_commands = {}


function console_commands.show_pathfinding_tile_nearest_entity(command)
    local player = game.get_player(command.player_index)
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
function console_commands.show_disjoint_tile_set(data)


    local surface = game.players[data.player_index].surface
    local ds = global.tiles_disjoint_sets[surface.index]

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
---@param data CustomCommandData|nil
function console_commands.recalculate_disjoint_tiles(data)
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

                if data and surface.index == game.players[data.player_index].surface.index then
                    highlight_tile(surface, {x=x, y=y}, parent)
                end
            end
        end
        global.tiles_disjoint_sets[surface.index] = ds
    end
end

---@param data CustomCommandData
function console_commands.test_two_tiles(data)
    
    local surface = game.players[data.player_index].surface
    
    local entities = surface.find_entities_filtered{name="wooden-chest", position=game.player.position, radius=100}
    if not entities or not entities[2] then
        util.print("no entity found")
        return
    end

    local set1 = util.get_path_sets_around(surface, entities[1].bounding_box)
    local set2 = util.get_path_sets_around(surface, entities[2].bounding_box)
    
    local ds = global.tiles_disjoint_sets[surface.index]

    local connected = false
    for _, pos1 in pairs(set1) do
        for _, pos2 in pairs(set2) do
            connected = connected or ds:isConnected(pos1, pos2)
        end
    end
    util.print(connected)

    -- Just for show:
    for _, pos1 in pairs(set1) do
        highlight_tile(surface, pos1, ds:find(ds:get_index(pos1)))
    end
    for _, pos2 in pairs(set2) do
        highlight_tile(surface, pos2, ds:find(ds:get_index(pos2)))
    end

    util.highlight_position(surface, entities[1].position, {r=1, g=0, b=0, a=0.5}, true)
    util.highlight_position(surface, entities[2].position, {r=1, g=0, b=0, a=0.5}, true)

end

return console_commands