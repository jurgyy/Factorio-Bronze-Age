for type in pairs(defines.prototypes.entity) do
    for _, prototype in pairs(data.raw[type]) do
        if prototype.minable then
            local recipe = data.raw.recipe[prototype.name]
            if recipe and (recipe.ingredients or recipe.normal) then
                local ingredients = (recipe.ingredients or recipe.normal.ingredients)
                local results = {}
                for _, ingredient in ipairs(ingredients) do
                    if ingredient.type ~= "fluid" then
                        table.insert(results, {
                            type = "item",
                            name = ingredient[1],
                            amount = ingredient[2]
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
        log(prototype.name)
    end
end