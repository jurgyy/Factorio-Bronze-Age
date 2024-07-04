local data_util = require("__bronze-age__/data/data-util")
local root = data_util.data_root .. "marble/"

data:extend{
    require(root .. "marble-item"),
}