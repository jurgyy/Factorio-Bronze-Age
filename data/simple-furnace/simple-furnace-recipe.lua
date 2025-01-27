return {
    type = "recipe",
    name = "simple-furnace",
    localised_name = {"simple-furnace"},
    enabled = true,
    ingredients =
    {
      {type = "item", name = "wood", amount = 10},
      {type = "item", name = "stone", amount = 5}
    },
    energy_required = 5,
    results = {{type = "item", name = "simple-furnace", amount = 1}}
}