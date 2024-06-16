local collision_util = require("collision-mask-util")

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

local worker_miner = table.deepcopy(data.raw["unit"]["mining-drone"])
local coal_resource = data.raw.resource["coal"]

worker_miner.name = "worker-miner"
data:extend{worker_miner, {
    type = "recipe",
    name = "ba-mine-coal",
    icon = coal_resource.icon,
    icon_size = coal_resource.icon_size,
    icons = coal_resource.icons,
    icon_mipmaps = coal_resource.icon_mipmaps,
    ingredients = {
        {type = "item", name = "worker-miner", amount = 1}
    },
    results = {{type = "item", name = "coal", amount = 0, show_details_in_recipe_tooltip = false}},
    category = "mining",
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

local worker_mask = table.deepcopy(worker_miner.collision_mask)
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