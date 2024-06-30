
local handcraft_recipe =  {
    type = "recipe",
    name = "unfired-clay-idol-hand-craft",
    localised_name = {"unfired-clay-idol"},
    enabled = true,
    ingredients = {
      {"clay", 3}
    },
    energy_required = 5,
    result = "unfired-clay-idol"
}

local pottery_recipe = table.deepcopy(handcraft_recipe)
pottery_recipe.name = "unfired-clay-idol"
pottery_recipe.category = "pottery"
pottery_recipe.hide_from_player_crafting = true

return {handcraft_recipe, pottery_recipe}