local data_util = require("__bronze-age__/data/data-util")
local root = data_util.data_root .. "oracle/"

local item = require(root .. "oracle-item")
local recipe = require(root .. "oracle-recipe")

data:extend{item, recipe}