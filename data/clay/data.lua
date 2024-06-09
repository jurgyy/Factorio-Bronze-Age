local data_util = require("__bronze-age__/data/data-util")
local root = data_util.data_root .. "clay/"

local item = require(root .. "clay-item")

data:extend{item}