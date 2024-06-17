local data_util = require("__bronze-age__/data/data-util")
local camp_defines = require("shared/camp-defines")

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

for _, camp in pairs(camp_defines.camps) do
    if not data.raw["item"][camp.worker_name] then
        local worker_item = table.deepcopy(data.raw["item"]["mining-drone"])
        worker_item.name = camp.worker_name
        worker_item.localised_name = worker_item.name
        worker_item.localised_description = nil
        data:extend{worker_item}
    end

    for _, cat in pairs(camp.crafting_categories) do
        if not data.raw["recipe-category"][cat] then
            local recipe_cat = {
                type = "recipe-category",
                name = cat
            }
            data:extend{recipe_cat}
        end
    end
end