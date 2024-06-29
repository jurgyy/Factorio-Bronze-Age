local data_util = require("__bronze-age__/data/data-util")
local root = data_util.data_root .. "unfired-pottery/"

data:extend{
    require(root .. "unfired-pottery-item"),
    require(root .. "unfired-pottery-recipe")
}