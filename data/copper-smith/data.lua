local data_util = require("__bronze-age__/data/data-util")
local root = data_util.data_root .. "copper-smith/"

local item = require(root .. "copper-smith-item")
local recipe = require(root .. "copper-smith-recipe")

data:extend{item, recipe}