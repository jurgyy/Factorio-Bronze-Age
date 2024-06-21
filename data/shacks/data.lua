local data_util = require("__bronze-age__/data/data-util")
local root = data_util.data_root .. "shacks/"

data:extend{
    require(root .. "shacks-item"),
    require(root .. "shacks-recipe"),
    require(root .. "shacks-entity")
}