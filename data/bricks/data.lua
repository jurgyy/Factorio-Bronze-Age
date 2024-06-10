local data_util = require("__bronze-age__/data/data-util")
local root = data_util.data_root .. "bricks/"

local item = require(root .. "bricks-item")

data:extend{
    item,
    require(root .. "bricks-recipe")
}