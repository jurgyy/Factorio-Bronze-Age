local data_util = require("__bronze-age__/data/data-util")
local root = data_util.data_root .. "simple-furnace/"

data:extend{
    require(root .. "simple-furnace-item"),
    require(root .. "simple-furnace-recipe"),
    require(root .. "simple-furnace-entity")
}