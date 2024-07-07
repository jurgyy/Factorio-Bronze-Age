local data_util = require("__bronze-age__/data/data-util")
local sounds = require("__base__/prototypes/entity/sounds")

--- @type data.Sprite4Way
local sprite = data_util.placeholder_4way(3, 3, {r=0.5, g=0.3, b=0.2, a=1})
local name = "pottery-workshop"

return {
    type = "assembling-machine",
    name = name,
    icon = data_util.icons_root .. "potter.png",
    icon_size = 64, icon_mipmaps = 4,
    flags = {"placeable-neutral","placeable-player", "player-creation"},
    minable = {mining_time = 0.2, result = name},
    max_health = 400,
    corpse = "assembling-machine-3-remnants",
    dying_explosion = "assembling-machine-3-explosion",
    alert_icon_shift = util.by_pixel(-3, -12),
    resistances =
    {
      {
        type = "fire",
        percent = 70
      }
    },
    open_sound = sounds.machine_open,
    close_sound = sounds.machine_close,
    vehicle_impact_sound = sounds.generic_impact,
    working_sound =
    {
      sound =
      {
        {
          filename = "__base__/sound/assembling-machine-t3-1.ogg",
          volume = 0.45
        }
      },
      audible_distance_modifier = 0.5,
      fade_in_ticks = 4,
      fade_out_ticks = 20
    },
    collision_box = {{-1.2, -1.2}, {1.2, 1.2}},
    selection_box = {{-1.5, -1.5}, {1.5, 1.5}},
    damaged_trigger_effect = nil,
    drawing_box = {{-1.5, -1.7}, {1.5, 1.5}},
    fast_replaceable_group = "assembling-machine",
    animation = {
        north = {
          layers = {
            sprite.north
          }
        },
        east = {
          layers = {
            sprite.east
          }
        },
        south = {
          layers = {
            sprite.south
          }
        },
        west = {
          layers = {
            sprite.west
          }
        }
    },

    crafting_categories = {"pottery", "pottery-or-handcrafting"},
    crafting_speed = 1,
    energy_source =
    {
      type = "electric",
      usage_priority = "secondary-input",
      emissions_per_minute = 2,
      drain = "0W"
    },
    energy_usage = "3W",
    module_specification =
    {
      module_slots = 4
    },
    allowed_effects = {"consumption", "speed", "productivity", "pollution"}
}