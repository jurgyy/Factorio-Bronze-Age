local data_util = require("__bronze-age__/data/data-util")
local root = data_util.data_root .. "simple-furnace/"

local item = require(root .. "simple-furnace-item")

data:extend{item}