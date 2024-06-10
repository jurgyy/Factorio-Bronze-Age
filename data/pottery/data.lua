local data_util = require("__bronze-age__/data/data-util")
local root = data_util.data_root .. "pottery/"

local item = require(root .. "pottery-item")
local recipe = require(root .. "pottery-recipe")

data:extend{item, recipe}