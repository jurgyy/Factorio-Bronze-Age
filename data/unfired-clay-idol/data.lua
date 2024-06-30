local data_util = require("__bronze-age__/data/data-util")
local root = data_util.data_root .. "unfired-clay-idol/"

local recipes = require(root .. "unfired-clay-idol-recipe")

data:extend{
    require(root .. "unfired-clay-idol-item"),
    recipes[1],
    recipes[2]
}