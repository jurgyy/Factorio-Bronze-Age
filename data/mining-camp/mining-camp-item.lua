local data_util = require("__bronze-age__/data/data-util")

return {
    type = "item",
    name = "mining-camp",
    icon = data_util.icons_root .. "mining-camp.png",
    icon_size = 64,
    icon_mipmaps = 1,
    flags = {},
    subgroup = "extraction-machine",
    order = "za-mining-camp",
    place_result = "mining-camp",
    stack_size = 50
}