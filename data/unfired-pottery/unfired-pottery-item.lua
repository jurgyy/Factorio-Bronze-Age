local data_util = require("__bronze-age__/data/data-util")

return {
    type = "item",
    name = "unfired-pottery",
    icon = data_util.icons_root .. "unfired-pottery.png",
    icon_size = 64,
    icon_mipmaps = 1,
    flags = {},
    subgroup = "raw-material",
    order = "za-unfired-pottery",
    stack_size = 50
}