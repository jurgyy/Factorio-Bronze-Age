local data_util = require("__bronze-age__/data/data-util")
local root = data_util.data_root .. "marble/"

local item = require(root .. "marble-item")

data:extend{item}