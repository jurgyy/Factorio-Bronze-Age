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


---@param data CustomCommandData
function console_commands.show_disjoint_tile_set(data)
    local function f(x)
        return math.sin(10000000/x)
    end

    local surface = game.players[data.player_index].surface
    local ds = global.tiles_disjoint_sets[surface.index]

    if ds then
        for x, parent_x in pairs(ds.parent) do
            for y, parent_xy in pairs(parent_x) do
                util.highlight_position(
                    surface,
                    {x = x, y = y},
                    {
                        r = 128 + 127 * f(parent_xy.x),
                        g = 128 + 127 * f(parent_xy.y),
                        b = 128 + 127 * f(parent_xy.x + parent_xy.y),
                        a = 128
                    },
                    true
                )
            end
        end
    end
end

---@param data CustomCommandData|nil
function console_commands.recalculate_disjoint_tiles(data)
    for _, surface in pairs(game.surfaces) do
        local ds = disjointSet.new()
         
        local path = surface.find_tiles_filtered{name="ba-path"}
        for _, tile in ipairs(path) do
            util.highlight_position(surface, tile.position, {r=0.5, b=0.5, g=0, a=0.5}, true)
            ds:add{tile=tile}
        end

        -- Compressing
        for x, parent_x in pairs(ds.parent) do
            for y, parent_xy in pairs(parent_x) do
                ds:find{x = x, y = y}
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
    
    local pos1 = entities[1].position
    local pos2 = entities[2].position

    util.highlight_position(surface, pos1, {r=1, g=0, b=0, a=0.5}, true)
    util.highlight_position(surface, pos2, {r=1, g=0, b=0, a=0.5}, true)

    local ds = global.tiles_disjoint_sets[surface.index]
    util.print(ds:isConnected(pos1, pos2))

end

return console_commands