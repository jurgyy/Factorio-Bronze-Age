local data_util = require("__bronze-age__/data/data-util")
local root = data_util.data_root .. "hephaestus-blessing/"

local item = require(root .. "hephaestus-blessing-item")
local recipe = require(root .. "hephaestus-blessing-recipe")

data:extend{item, recipe}