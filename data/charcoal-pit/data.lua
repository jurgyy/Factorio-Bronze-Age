local data_util = require("__bronze-age__/data/data-util")
local root = data_util.data_root .. "charcoal-pit/"

data:extend{
    require(root .. "charcoal-pit-item"),
    require(root .. "charcoal-pit-recipe"),
    require(root .. "charcoal-pit-entity")
}