local data_util = require("__bronze-age__/data/data-util")
local root = data_util.data_root .. "charcoal/"

local item = require(root .. "charcoal-item")

data:extend{item}