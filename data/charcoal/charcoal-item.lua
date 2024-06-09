local data_util = require("__bronze-age__/data/data-util")

return {
    type = "item",
    name = "charcoal",
    icon = data_util.icons_root .. "charcoal.png",
    icon_size = 64,
    icon_mipmaps = 1,
    flags = {},
    subgroup = "raw-material",
    order = "za-charcoal",
    stack_size = 50
}