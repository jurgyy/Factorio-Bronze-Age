local data_util = require("__bronze-age__/data/data-util")
local root = data_util.data_root .. "pottery/"

data:extend{
    require(root .. "pottery-item"),
    require(root .. "pottery-recipe")
}