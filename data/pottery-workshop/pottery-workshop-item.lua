local data_util = require("__bronze-age__/data/data-util")

return {
    type = "item",
    name = "pottery-workshop",
    icon = data_util.icons_root .. "potter.png",
    icon_size = 64,
    icon_mipmaps = 1,
    flags = {},
    subgroup = "production-machine",
    order = "za-pottery-workshop",
    place_result = "pottery-workshop",
    stack_size = 50
}