local data_util = require("__bronze-age__/data/data-util")
local root = data_util.data_root .. "unfired-clay-disk/"

data:extend{
    require(root .. "unfired-clay-disk-item"),
    require(root .. "unfired-clay-disk-recipe"),
}