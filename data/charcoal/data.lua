local data_util = require("__bronze-age__/data/data-util")
local root = data_util.data_root .. "charcoal/"

data:extend{
    require(root .. "charcoal-item"),
    require(root .. "charcoal-recipe")
}