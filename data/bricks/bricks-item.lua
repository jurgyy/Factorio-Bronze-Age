local data_util = require("__bronze-age__/data/data-util")

return {
    type = "item",
    name = "bricks",
    icon = data_util.icons_root .. "bricks.png",
    icon_size = 64,
    icon_mipmaps = 1,
    flags = {},
    subgroup = "raw-material",
    order = "za-bricks",
    stack_size = 100
}