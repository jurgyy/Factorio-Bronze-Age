local data_util = require("__bronze-age__/data/data-util")

local entity = require(data_util.data_root .. "loggers-camp/loggers-camp-entity")
local item = require(data_util.data_root .. "loggers-camp/loggers-camp-item")
local recipe = require(data_util.data_root .. "loggers-camp/loggers-camp-recipe")

data:extend{entity, item, recipe}