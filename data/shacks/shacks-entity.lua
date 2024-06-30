local data_util = require("__bronze-age__/data/data-util")

local sprite = data_util.place_holder_sprite(2, 2)

return {
    type = "solar-panel",
    name = "shacks",
    icon = "__base__/graphics/icons/solar-panel.png",
    icon_size = 64, icon_mipmaps = 1,
    flags = {"placeable-neutral", "player-creation"},
    minable = {mining_time = 0.1, result = "shacks"},
    max_health = 200,
    corpse = nil, --TODO
    dying_explosion = "solar-panel-explosion",
    collision_box = {{-0.9, -0.9}, {0.9, 0.9}},
    selection_box = {{-1, -1}, {1, 1}},
    damaged_trigger_effect = nil,
    energy_source =
    {
      type = "electric",
      usage_priority = "solar"
    },
    picture =
    {
      layers =
      {
        sprite
      }
    },
    vehicle_impact_sound = nil,
    production = "3W",
}