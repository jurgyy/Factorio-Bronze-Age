local data_util = require("__bronze-age__/data/data-util")
local root = data_util.data_root .. "forge/"

data:extend{
    require(root .. "forge-item"),
    require(root .. "forge-recipe"),
    require(root .. "forge-entity"),
}