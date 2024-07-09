local data_util = require("__bronze-age__/data/data-util")

return {
    type = "item",
    name = "clay-disk",
    icon = data_util.icons_root .. "clay-disk.png",
    icon_size = 64,
    icon_mipmaps = 1,
    flags = {},
    subgroup = "raw-material",
    order = "za-clay-disk",
    stack_size = 50
}