local data_util = require("__bronze-age__/data/data-util")
local root = data_util.data_root .. "tin-ore/"

local item = require(root .. "tin-ore-item")

data:extend{item}