local data_util = require("__bronze-age__/data/data-util")

return {
    type = "item",
    name = "charcoal-pit",
    icon = data_util.icons_root .. "charcoal-pit.png",
    icon_size = 64,
    icon_mipmaps = 1,
    flags = {},
    subgroup = "production-machine",
    order = "za-charcoal-pit",
    place_result = "charcoal-pit",
    stack_size = 50
}