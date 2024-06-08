
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

