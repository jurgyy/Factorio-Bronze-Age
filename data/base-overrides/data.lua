local data_util = require("__bronze-age__/data/data-util")
local root = data_util.data_root .. "base-overrides/"

require(root .. "inserters")

-- limitations reference recipes hence why they have to be removed
for name, module_prototype in pairs(data.raw["module"]) do
    module_prototype.limitation = nil
end

for name, recipe_prototype in pairs(data.raw["recipe"]) do
    data.raw["recipe"][name] = nil
end

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

data.raw["rocket-silo"]["rocket-silo"].fixed_recipe = nil

data:extend(require(root .. "recipes"))