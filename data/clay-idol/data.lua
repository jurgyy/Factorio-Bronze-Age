local data_util = require("__bronze-age__/data/data-util")
local root = data_util.data_root .. "clay-idol/"

data:extend{
    require(root .. "clay-idol-item"),
    require(root .. "clay-idol-recipe")
}