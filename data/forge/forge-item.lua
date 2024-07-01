local data_util = require("__bronze-age__/data/data-util")

return {
    type = "item",
    name = "forge",
    icon = data_util.icons_root .. "forge.png",
    icon_size = 64,
    icon_mipmaps = 1,
    flags = {},
    subgroup = "production-machine",
    order = "za-forge",
    place_result = "forge",
    stack_size = 50
}