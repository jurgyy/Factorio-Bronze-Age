local data_util = require("__bronze-age__/data/data-util")
local root = data_util.data_root .. "clay-disk/"

data:extend{
    require(root .. "clay-disk-item"),
    require(root .. "clay-disk-recipe")
}