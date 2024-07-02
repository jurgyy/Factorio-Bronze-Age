local data_util = {}

data_util.root = "__bronze-age__/"
data_util.data_root = data_util.root .. "data/"
data_util.graphics_root = data_util.root .. "graphics/"
data_util.icons_root = data_util.graphics_root .. "icons/"
data_util.tech_icons_root = data_util.graphics_root .. "technology/"

---@param width integer
---@param height integer
---@param tint Color?
---@return data.Sprite
function data_util.place_holder_sprite(width, height, tint)
    return {
        filename = "__bronze-age__/graphics/placeholder/construction/construction-"..width.."-"..height..".png",
        priority = "extra-high",
        width = width * 64,
        height = height * 64 + 16,
        shift = util.by_pixel(-0.25, -0.5),
        tint = tint,
        scale = 0.5,
        hr_version =
        {
            filename = "__bronze-age__/graphics/placeholder/construction/construction-"..width.."-"..height..".png",
            priority = "extra-high",
            width = width * 64,
            height = height * 64 + 16,
            shift = util.by_pixel(-0.25, -0.5),
            tint = tint,
            scale = 0.5
        }
    }
end

---@param width integer
---@param height integer
---@param direction "N"|"E"|"S"|"W"?
---@param tint Color?
---@return data.Sprite
local function get_one_way(width, height, direction, tint)
    local widthpx, heightpx
    if not direction or direction == "N" then
        direction = "N"
        widthpx = width * 64
        heightpx = height * 64 + 16
    elseif direction == "E" then
        widthpx = height * 64 + 16
        heightpx = width * 64
    elseif direction == "S" then
        widthpx = width * 64
        heightpx = height * 64 + 16
    elseif direction == "W" then
        widthpx = height * 64 + 16
        heightpx = width * 64
    else
        error("Unknown direction " .. direction)
    end
    return {
        filename = "__bronze-age__/graphics/placeholder/construction/"..direction.."/construction-"..width.."-"..height..".png",
        priority = "extra-high",
        width = widthpx,
        height = heightpx,
        shift = util.by_pixel(-0.25, -0.5),
        scale = 0.5,
        tint = tint,
        hr_version =
        {
            filename = "__bronze-age__/graphics/placeholder/construction/"..direction.."/construction-"..width.."-"..height..".png",
            priority = "extra-high",
            width = widthpx,
            height = heightpx,
            shift = util.by_pixel(-0.25, -0.5),
            scale = 0.5,
            tint = tint
        }
    }
end

---@param width integer
---@param height integer
---@param tint Color?
---@return data.Sprite4Way
function data_util.placeholder_4way(width, height, tint)
    return {
        north = get_one_way(width, height, "N", tint),
        east = get_one_way(width, height, "E", tint),
        south = get_one_way(width, height, "S", tint),
        west = get_one_way(width, height, "W", tint)
    }
end

return data_util