local data_util = require("__bronze-age__/data/data-util")
local root = data_util.data_root .. "unfired-bricks/"

data:extend{
    require(root .. "unfired-bricks-item"),
    require(root .. "unfired-bricks-recipe")
}