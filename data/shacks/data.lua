local data_util = require("__bronze-age__/data/data-util")
local root = data_util.data_root .. "shacks/"

local item = require(root .. "shacks-item")
local recipe = require(root .. "shacks-recipe")

data:extend{item, recipe}