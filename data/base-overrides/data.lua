local data_util = require("__bronze-age__/data/data-util")
local root = data_util.data_root .. "base-overrides/"

require(root .. "inserters")

-- limitations reference recipes hence why they have to be removed
-- for name, module_prototype in pairs(data.raw["module"]) do
--     module_prototype.limitation = nil
-- end

local old_recipes = data.raw.recipe
data.raw.recipe = {["recipe-unknown"] = old_recipes["recipe-unknown"]}

for name, tech_prototype in pairs(data.raw["technology"]) do
    data.raw["technology"][name] = nil
end

for name, shortcut_prototype in pairs(data.raw["shortcut"]) do
    shortcut_prototype.technology_to_unlock = nil
end

for name, prototype in pairs(data.raw["tips-and-tricks-item"]) do
    data.raw["tips-and-tricks-item"][name] = nil
end

for name, prototype in pairs(data.raw["research-achievement"]) do
    data.raw["research-achievement"][name] = nil
end

for name, prototype --[[@as data.InserterPrototype]] in pairs(data.raw["inserter"]) do
    if prototype.energy_source.type == "burner" then
        prototype.energy_source.fuel_categories = {"wood-burn"}
    end
end

data.raw["rocket-silo"]["rocket-silo"].fixed_recipe = nil

data:extend(require(root .. "recipes"))