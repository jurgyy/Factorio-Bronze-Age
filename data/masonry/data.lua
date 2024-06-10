local data_util = require("__bronze-age__/data/data-util")
local root = data_util.data_root .. "masonry/"

local item = require(root .. "masonry-item")
local recipe = require(root .. "masonry-recipe")

data:extend{item, recipe}