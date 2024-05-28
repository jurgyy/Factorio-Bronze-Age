for type in pairs(defines.prototypes.entity) do
    for _, prototype in pairs(data.raw[type]) do
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