local data_util = {}

data_util.root = "__bronze-age__/"
data_util.data_root = data_util.root .. "data/"
data_util.graphics_root = data_util.root .. "graphics/"
data_util.icons_root = data_util.graphics_root .. "icons/"

---@param width integer
---@param height integer
---@return data.Sprite
function data_util.place_holder_sprite(width, height)
    return {
        filename = "__bronze-age__/graphics/placeholder/construction/construction-"..width.."-"..height..".png",
        priority = "extra-high",
        width = width * 64,
        height = height * 64 + 16,
        shift = util.by_pixel(-0.25, -0.5),
        scale = 0.5,
        hr_version =
        {
            filename = "__bronze-age__/graphics/placeholder/construction/construction-"..width.."-"..height..".png",
            priority = "extra-high",
            width = width * 64,
            height = height * 64 + 16,
            shift = util.by_pixel(-0.25, -0.5),
            scale = 0.5
        }
    }
end

return data_util