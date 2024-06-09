local data_util = require("__bronze-age__/data/data-util")

return {
    type = "item",
    name = "flowers",
    icon = data_util.icons_root .. "flowers.png",
    icon_size = 64,
    icon_mipmaps = 1,
    flags = {},
    subgroup = "raw-resource",
    order = "za-flowers",
    stack_size = 50
}