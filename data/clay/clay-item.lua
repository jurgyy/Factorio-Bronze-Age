local data_util = require("__bronze-age__/data/data-util")

return {
    type = "item",
    name = "clay",
    icon = data_util.icons_root .. "clay.png",
    icon_size = 64,
    icon_mipmaps = 1,
    flags = {},
    subgroup = "raw-resource",
    order = "za-clay",
    stack_size = 50
}