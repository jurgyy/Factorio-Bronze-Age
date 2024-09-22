local ceil = math.ceil
local floor = math.floor

local collision_util = {}

---Get the bounding square bounding boxes around an entity.
---@param entity LuaEntity
---@param offset integer?
---@return BoundingBox
function collision_util.get_areas_around(entity, offset)
    offset = offset or 0
    local box = entity.selection_box
    if not box then error("Entity has no selection box") end

    return {
        left_top = {
            x = floor(box.left_top.x - offset),
            y = floor(box.left_top.y - offset)
        },
        right_bottom = {
            x = ceil(box.right_bottom.x + offset),
            y = ceil(box.right_bottom.y + offset)
        }
    }
    -- local collision_box = entity.prototype.collision_box
    -- local width = ceil(collision_box.right_bottom.x - collision_box.left_top.x)
    -- local height = ceil(collision_box.right_bottom.y - collision_box.left_top.y)

    -- if width == height then
    --     return {{
    --         left_top = {
    --             x = floor(entity.position.x - collision_box.left_top.x - offset),
    --             y = floor(entity.position.y - collision_box.left_top.y - offset),
    --         },
    --         right_botom = {
    --             x = ceil(entity.position.x + collision_box.left_top.x + offset),
    --             y = ceil(entity.position.y + collision_box.left_top.y + offset),
    --         }
    --     }}
    -- end
    
    -- if entity
end

return collision_util