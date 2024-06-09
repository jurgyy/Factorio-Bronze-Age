local data_util = require("__bronze-age__/data/data-util")

return {
    type = "item",
    name = "loggers-camp",
    icon = data_util.icons_root .. "loggers-camp.png",
    icon_size = 64,
    icon_mipmaps = 1,
    flags = {},
    subgroup = "extraction-machine",
    order = "za-logger",
    place_result = "loggers-camp",
    stack_size = 10
}