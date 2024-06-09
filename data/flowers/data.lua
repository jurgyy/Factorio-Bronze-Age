local data_util = require("__bronze-age__/data/data-util")
local root = data_util.data_root .. "flowers/"

local item = require(root .. "flowers-item")

data:extend{item}