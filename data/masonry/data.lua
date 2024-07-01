local data_util = require("__bronze-age__/data/data-util")
local root = data_util.data_root .. "masonry/"

data:extend{
    require(root .. "masonry-item"),
    require(root .. "masonry-recipe"),
    require(root .. "masonry-entity")
}