local data_util = require("__bronze-age__/data/data-util")

return {
    type = "item",
    name = "tin-ore",
    icon = data_util.icons_root .. "tin-ore.png",
    icon_size = 64,
    icon_mipmaps = 1,
    flags = {},
    subgroup = "raw-resource",
    order = "za-tin-ore",
    stack_size = 50
}