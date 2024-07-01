local data_util = require("__bronze-age__/data/data-util")
local root = data_util.data_root .. "copper-smith/"

data:extend{
    require(root .. "copper-smith-item"),
    require(root .. "copper-smith-recipe"),
    require(root .. "copper-smith-entity")
}