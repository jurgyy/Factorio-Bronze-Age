local data_util = require("__bronze-age__/data/data-util")
local root = data_util.data_root .. "potter/"

local item = require(root .. "potter-item")
local recipe = require(root .. "potter-recipe")

data:extend{item, recipe}