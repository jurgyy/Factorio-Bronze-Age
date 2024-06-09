local data_util = require("__bronze-age__/data/data-util")

return {
    type = "item",
    name = "copper-tools",
    icon = data_util.icons_root .. "copper-tools.png",
    icon_size = 64,
    icon_mipmaps = 1,
    flags = {},
    subgroup = "raw-material",
    order = "za-copper-tools",
    stack_size = 50
}