local flib_bounding_box = require("__flib__/bounding-box")

local util = require("ba-util")
local PathfindingCollection = require("PathfindingCollection")


local pathfinding = {}

---comments
---@param surface LuaSurface
---@param entity_prototype LuaEntityPrototype
---@param start MapPosition
---@param goal MapPosition
local function can_path(surface, entity_prototype, start, goal)
    surface.request_path {
        bounding_box = entity_prototype.collision_box,
        collision_mask = entity_prototype.collision_mask,
        start = start,
        goal = goal,
        force = game.players[1].force,
    }
end

---comments
---@param item SimpleItemStack
---@param goal_entity LuaEntity
---@param unit_prototype LuaEntityPrototype
---@param search_radius number
---@return PathfindingCollection?
function pathfinding.get_chest_pathfinding_collection(item, goal_entity, unit_prototype, search_radius)
    local surface = goal_entity.surface
    local bbox = flib_bounding_box.from_position(goal_entity.position, true)
    bbox = flib_bounding_box.resize(bbox, search_radius)
    util.highlight_bbox(surface, bbox)

    local destinations = util.get_path_sets_around(surface, goal_entity.bounding_box)
    if #destinations == 0 then
        util.print("Goal not connected to path")
        return
    end
    local chests = surface.find_entities_filtered{
        name = "wooden-chest",
        position = goal_entity.position,
        radius = search_radius
    }

    local pathfinding_collection = PathfindingCollection.new(surface.index, item.count, unit_prototype)
    --local partial_candidates = {}
    for _, chest in pairs(chests) do
        local inventory = chest.get_output_inventory()
        if not inventory then
            goto continue
        end

        local stack = inventory.find_item_stack(item.name)
        if not stack then
            goto continue
        end

        local starts = util.get_path_sets_around(surface, chest.bounding_box)
        for _, start in ipairs(starts) do
            for _, goal in destinations  do
                pathfinding_collection.add_path{
                    start = start,
                    goal = goal,
                    weight = item.count,
                    start_enity = chest
                }
            end
        end

        ::continue::
    end

    return pathfinding_collection
end

return pathfinding