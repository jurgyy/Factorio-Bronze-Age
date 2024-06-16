local data_util = require("__bronze-age__/data/data-util")

require(data_util.data_root .. "bricks/data")
require(data_util.data_root .. "charcoal/data")
require(data_util.data_root .. "clay/data")
require(data_util.data_root .. "copper-ingot/data")
require(data_util.data_root .. "copper-smith/data")
require(data_util.data_root .. "copper-tools/data")
require(data_util.data_root .. "flowers/data")
require(data_util.data_root .. "forge/data")
require(data_util.data_root .. "hephaestus-blessing/data")
require(data_util.data_root .. "loggers-camp/data")
require(data_util.data_root .. "marble/data")
require(data_util.data_root .. "masonry/data")
require(data_util.data_root .. "mining-camp/data")
require(data_util.data_root .. "oracle/data")
require(data_util.data_root .. "potter/data")
require(data_util.data_root .. "pottery/data")
require(data_util.data_root .. "shacks/data")
require(data_util.data_root .. "simple-furnace/data")
require(data_util.data_root .. "tin-ore/data")

require(data_util.data_root .. "technology")

require(data_util.data_root .. "resource-categories")

local worker_miner = table.deepcopy(data.raw["item"]["mining-drone"])
worker_miner.name = "worker-miner"
data:extend{worker_miner}