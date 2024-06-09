local data_util = require("__bronze-age__/data/data-util")
local root = data_util.data_root .. "copper-tools/"

local item = require(root .. "copper-tools-item")

data:extend{item}