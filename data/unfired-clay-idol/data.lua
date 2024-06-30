local data_util = require("__bronze-age__/data/data-util")
local root = data_util.data_root .. "unfired-clay-idol/"

data:extend{
    require(root .. "unfired-clay-idol-item"),
    require(root .. "unfired-clay-idol-recipe"),
}