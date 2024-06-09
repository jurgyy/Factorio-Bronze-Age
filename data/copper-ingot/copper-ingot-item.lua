local data_util = require("__bronze-age__/data/data-util")

return {
    type = "item",
    name = "copper-ingot",
    icon = data_util.icons_root .. "copper-ingot.png",
    icon_size = 64,
    icon_mipmaps = 1,
    flags = {},
    subgroup = "raw-material",
    order = "za-copper-ingot",
    stack_size = 50
}