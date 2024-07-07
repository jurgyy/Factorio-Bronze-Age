local data_util = require("__bronze-age__/data/data-util")
local sounds = require("__base__/prototypes/entity/sounds")

--- @type data.Sprite4Way
local sprite = data_util.place_holder_sprite(3, 3, {r=0.2, g=0.3, b=0.8, a=1})
local name = "oracle"

return {
    type = "lab",
    name = name,
    icon = "__base__/graphics/icons/lab.png",
    icon_size = 64, icon_mipmaps = 4,
    flags = {"placeable-player", "player-creation"},
    minable = {mining_time = 0.2, result = name},
    max_health = 150,
    corpse = "lab-remnants",
    dying_explosion = "lab-explosion",
    collision_box = {{-1.2, -1.2}, {1.2, 1.2}},
    selection_box = {{-1.5, -1.5}, {1.5, 1.5}},
    damaged_trigger_effect = nil, --hit_effects.entity(),
    on_animation = sprite,
    off_animation = sprite,
    working_sound =
    {
      sound =
      {
        filename = "__base__/sound/lab.ogg",
        volume = 0.7
      },
      audible_distance_modifier = 0.7,
      fade_in_ticks = 4,
      fade_out_ticks = 20
    },
    vehicle_impact_sound = sounds.generic_impact,
    open_sound = sounds.machine_open,
    close_sound = sounds.machine_close,
    energy_source =
    {
      type = "electric",
      usage_priority = "secondary-input",
      drain = "0W"
    },
    energy_usage = "10W",
    researching_speed = 1,
    inputs = {"hephaestus-blessing"},
    module_specification =
    {
      module_slots = 2,
      module_info_icon_shift = {0, 0.9}
    }
}