local data_util = require("__bronze-age__/data/data-util")

return {
    type = "item",
    name = "clay-idol",
    icon = data_util.icons_root .. "clay-idol.png",
    icon_size = 64,
    icon_mipmaps = 1,
    flags = {},
    subgroup = "raw-material",
    order = "za-clay-idol",
    stack_size = 50
}