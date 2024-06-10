local data_util = require("__bronze-age__/data/data-util")
local root = data_util.data_root .. "mining-camp/"

local item = require(root .. "mining-camp-item")
local recipe = require(root .. "mining-camp-recipe")

data:extend{item, recipe}