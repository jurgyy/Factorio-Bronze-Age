local data_util = require("__bronze-age__/data/data-util")

return {
    type = "item",
    name = "pottery",
    icon = data_util.icons_root .. "pottery.png",
    icon_size = 64,
    icon_mipmaps = 1,
    flags = {},
    subgroup = "raw-material",
    order = "za-pottery",
    stack_size = 50
}