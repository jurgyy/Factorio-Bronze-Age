local data_util = require("__bronze-age__/data/data-util")

return {
    type = "item",
    name = "masonry",
    icon = data_util.icons_root .. "masonry.png",
    icon_size = 64,
    icon_mipmaps = 1,
    flags = {},
    subgroup = "production-machine",
    order = "za-masonry",
    place_result = "masonry",
    stack_size = 50
}