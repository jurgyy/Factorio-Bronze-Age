local data_util = require("__bronze-age__/data/data-util")

return {
    type = "item",
    name = "simple-furnace",
    icon = data_util.icons_root .. "simple-furnace.png",
    icon_size = 64,
    icon_mipmaps = 1,
    flags = {},
    subgroup = "production-machine",
    order = "za-simple-furnace",
    place_result = "simple-furnace",
    stack_size = 50
}