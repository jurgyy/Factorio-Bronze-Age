local data_util = require("__bronze-age__/data/data-util")
local root = data_util.data_root .. "copper-ingot/"

local item = require(root .. "copper-ingot-item")
local recipe = require(root .. "copper-ingot-recipe")

data:extend{item, recipe}