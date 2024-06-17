local collision_util = require("collision-mask-util")
local camp_defines = require("shared/camp-defines")

local function startswith(str, start)
    return string.sub(str, 1, string.len(start)) == start
end

collisions = {}

for type in pairs(defines.prototypes.entity) do
    for _, prototype in pairs(data.raw[type]) do
        ---@cast prototype LuaEntityPrototype

        local box = prototype.collision_box
        if not (startswith(prototype.name, "construction-")) and box then
            local width = math.ceil(box[2][1] - box[1][1])
            local height = math.ceil(box[2][2] - box[1][2])
            local index = width .. "," .. height
            if not collisions[index] then
                collisions[index] = {}
            end
            table.insert(collisions[index], prototype.name)
        end

        if prototype.minable then
            local recipe = data.raw.recipe[prototype.minable.result]
            if recipe and (recipe.ingredients or recipe.normal) then
                local ingredients = (recipe.ingredients or recipe.normal.ingredients)
                local multiplier = 1
                if prototype.name == "curved-rail" then
                    multiplier = 4
                end
                local results = {}
                if recipe.result_count and recipe.result_count > 1 then
                    log("Modifying the result_count for " .. recipe.name .. " from " .. recipe.result_count .. " to 1")
                    recipe.result_count = 1
                end
                for _, ingredient in ipairs(ingredients) do
                    if ingredient.type ~= "fluid" then
                        table.insert(results, {
                            type = "item",
                            name = ingredient[1],
                            amount = ingredient[2] * multiplier
                        })
                    else
                        log(prototype.name .. " Skipping fluid ingredient")
                    end
                end
                prototype.minable = {
                    mining_time = prototype.minable.mining_time,
                    results = results
                }
            else
                log("No recipe for " .. prototype.name)
            end
        end
    end
end

for shape, prototypes in pairs(collisions) do
    log("Shape " .. shape .. ": " .. table.concat(prototypes, ", "))
end


for name, worker_def in pairs(camp_defines.workers) do
    local worker = table.deepcopy(data.raw["unit"]["mining-drone"])
    worker.name = name
    worker.localised_name = nil
    worker.localised_description = nil
    data:extend{worker}
end

for _, camp in pairs(camp_defines.camps) do
    local worker = data.raw["unit"]["mining-drone"]
    local worker_mask = table.deepcopy(worker.collision_mask)
    collision_util.remove_layer(worker_mask, "doodad-layer")
    if worker_mask then
        for _, layer in pairs(worker_mask) do
            local mining_camp = data.raw["assembling-machine"]["mining-camp"]
            if mining_camp then
                log("Removing layer " .. layer .. " from collision mask of " .. mining_camp.name)
                collision_util.remove_layer(mining_camp.collision_mask, layer)
            end
        end
    end

    for name, recipe in pairs(camp.recipes) do
        local resource_item = data.raw.item[recipe.resource]
        
        data:extend{{
            type = "recipe",
            name = name,
            icon = resource_item.icon,
            icon_size = resource_item.icon_size,
            icons = resource_item.icons,
            icon_mipmaps = resource_item.icon_mipmaps,
            ingredients = {
                {type = "item", name = camp.worker_name, amount = 1}
            },
            results = {{type = "item", name = recipe.resource, amount = 0, show_details_in_recipe_tooltip = false}},
            category = recipe.category,
            subgroup = "extraction-machine",
            --overload_multiplier = 100,
            hide_from_player_crafting = true,
            main_product = "",
            allow_decomposition = false,
            allow_as_intermediate = false,
            allow_intermediates = true,
            order = "zzzzz",
            allow_inserter_overload = false,
            energy_required = 1.166
        }}
    end
end
