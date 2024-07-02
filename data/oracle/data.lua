local data_util = require("__bronze-age__/data/data-util")
local root = data_util.data_root .. "oracle/"

data:extend{
    require(root .. "oracle-item"),
    require(root .. "oracle-recipe"),
    require(root .. "oracle-entity")
}