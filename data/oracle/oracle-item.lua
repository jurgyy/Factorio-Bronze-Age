local data_util = require("__bronze-age__/data/data-util")

return {
    type = "item",
    name = "oracle",
    icon = data_util.icons_root .. "oracle.png",
    icon_size = 64,
    icon_mipmaps = 1,
    flags = {},
    subgroup = "production-machine",
    order = "za-oracle",
    place_result = "oracle",
    stack_size = 50
}