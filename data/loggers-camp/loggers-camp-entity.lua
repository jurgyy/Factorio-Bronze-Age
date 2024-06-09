local data_util = require("__bronze-age__/data/data-util")

--- @type data.Sprite
local sprite = data_util.place_holder_sprite(3,3)

return {
    name = "loggers-camp",
    type = "assembling-machine",
    collision_box = {{-1.35, -1.35}, {1.35, 1.35}},
    selection_box = {{-1.5, -1.5}, {1.5, 1.5}},
    allowed_effects = {},
    close_sound =
    {
      {
        filename = "__base__/sound/machine-close.ogg",
        volume = 0.5
      }
    },
    --collision_mask = {}, -- using the default collision_mask
    corpse = "accumulator-remnants",
    crafting_categories = {"logging"},
    crafting_speed = 1,
    damaged_trigger_effect =
    {
      damage_type_filters = "fire",
      entity_name = "spark-explosion",
      offset_deviation = {{ -0.5, -0.5}, { 0.5, 0.5}},
      offsets = {{ 0, 1}},
      type = "create-entity"
    },
    drawing_box = {{-1, -1}, {1, 1}},
    dying_explosion = "accumulator-explosion",
    energy_source =
    {
      emissions_per_second_per_watt = 0.1,
      type = "void",
      usage_priority = "secondary-input"
    },
    energy_usage = "1W",
    fast_replaceable_group = "assembling-machine",
    flags =
    {
      "placeable-neutral",
      "player-creation"
    },
    icon = "__base__/graphics/icons/wood.png",
    icon_size = 64,
    icon_mipmaps = 4,
    max_health = 100,
    minable =
    {
      mining_time = 1,
      result = "loggers-camp"
    },
    open_sound =
    {
      {
        filename = "__base__/sound/machine-open.ogg",
        volume = 0.5
      }
    },
    animation = {
      layers = {
        sprite
      }
    }
}
