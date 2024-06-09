local data_util = require("__bronze-age__/data/data-util")

return {
    type = "item",
    name = "copper-smith",
    icon = data_util.icons_root .. "copper-smith.png",
    icon_size = 64,
    icon_mipmaps = 1,
    flags = {},
    subgroup = "production-machine",
    order = "za-copper-smith",
    stack_size = 50
}