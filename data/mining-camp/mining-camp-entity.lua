local data_util = require("__bronze-age__/data/data-util")
local camps_data = require("shared/camp-defines")

--- @type data.Sprite
local sprite = data_util.place_holder_sprite(3,5)
sprite.tint = {r=0.3, g=0.3, b=0.3, a=1}
sprite.hr_version.tint = sprite.tint

local name = "mining-camp"
local camp_data = camps_data.camps[name]
if not camp_data then error("unknown camp " .. name) end

return {
    name = name,
    type = "assembling-machine",
    collision_box = {{-1.35, -2.35}, {1.35, 2.35}},
    selection_box = {{-1.5, -2.5}, {1.5, 2.5}},
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
    crafting_categories = camp_data.crafting_categories,
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
    icon = data_util.icons_root .. "mining-camp.png",
    icon_size = 64,
    icon_mipmaps = 1,
    max_health = 100,
    minable =
    {
      mining_time = 0.1,
      result = name
    },
    open_sound =
    {
      {
        filename = "__base__/sound/machine-open.ogg",
        volume = 0.5
      }
    },
    working_visualisations = {{
      always_draw = true,
      render_layer = "object",
      north_animation = {
        layers = {
          sprite
        }
      },
      east_animation = {
        layers = {
          sprite
        }
      },
      south_animation = {
        layers = {
          sprite
        }
      },
      west_animation = {
        layers = {
          sprite
        }
      }}
    },
    radius_visualisation_specification =
    {
      distance =  camp_data.mining_radius,
      offset = {0, (-camp_data.mining_radius_offset - camp_data.mining_radius) - 0.5},
      sprite =
      {
        filename = "__base__/graphics/entity/electric-mining-drill/electric-mining-drill-radius-visualization.png",
        height = 10,
        width = 10
      }
    }
}
