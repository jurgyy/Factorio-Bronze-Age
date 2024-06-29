local data_util = require("__bronze-age__/data/data-util")
local root = data_util.data_root .. "pottery-workshop/"

data:extend{
    require(root .. "pottery-workshop-item"),
    require(root .. "pottery-workshop-recipe"),
    require(root .. "pottery-workshop-entity")
}