local util = require("ba-util")
local collision_util = require("collision-mask-util")
require("__bronze-age__/data/data")

local function gaussian (mean, variance)
    return  math.sqrt(-2 * variance * math.log(math.random())) *
            math.cos(2 * math.pi * math.random()) + mean
end

local ammo_category = function(name)
  if not data.raw["ammo-category"][name] then
    data:extend{{type = "ammo-category", name = name, localised_name = {name}}}
  end
  return name
end

local damage_type = function(name)
  if not data.raw["damage-type"][name] then
    data:extend{{type = "damage-type", name = name, localised_name = {name}}}
  end
  return name
end

local worker_collision_mask =
{
  "ground-tile",
  "water-tile",
  "resource-layer",
  "doodad-layer",
  "floor-layer",
  "item-layer",
  "ghost-layer",
  "object-layer",
  --"player-layer",
  --"train-layer",
  "rail-layer",
  "transport-belt-layer"
}

-- for k = 13, 55 do
--   table.insert(layer_names, "layer-"..k)
-- end

local bot_name = "ba-worker"
local bot_name_2 = bot_name
local worker_flags = {"placeable-off-grid", "hidden", "not-in-kill-statistics"}

local random_mining_speed = 1.5 * 1 + ((math.random() - 0.5) / 4)
local random_height = gaussian(90, 10) / 100
local base = util.copy(data.raw.character.character)

local worker = {
    type = "unit",
    name = bot_name,
    localised_name = {bot_name_2},
    icon = "__Mining_Drones__/data/icons/mining_drone.png",
    icon_size = 64,
    icons = {
      {
        icon = "__Mining_Drones__/data/icons/mining_drone.png",
        icon_size = 64,
      }
    },
    flags = worker_flags,
    map_color = {200 ^ 0.5, 200 ^ 0.5, 200 ^ 0.5, 0.5},
    enemy_map_color = {r = 1},
    max_health = 150,
    radar_range = 1,
    order="zzz-"..bot_name,
    --subgroup = "iron-units",
    healing_per_tick = 0.1,
    --minable = {result = name, mining_time = 2},
    collision_box = {{-0.18, -0.18}, {0.18, 0.18}},
    collision_mask = worker_collision_mask,
    --render_layer = "object",
    render_layer = "lower-object-above-shadow",
    max_pursue_distance = 64,
    resistances = nil,
    min_persue_time = 60 * 15,
    selection_box = {{-0.3, -0.3}, {0.3, 0.3}},
    sticker_box = {{-0.3, -1}, {0.2, 0.3}},
    distraction_cooldown = (15),
    move_while_shooting = false,
    can_open_gates = true,
    not_controllable = true,
    ai_settings =
    {
      do_separation = false
    },
    attack_parameters =
    {
      type = "projectile",
      ammo_category = "bullet",
      warmup = math.floor(19 * random_mining_speed),
      cooldown = math.floor((26 - 19) * random_mining_speed),
      range = 0.5,
      ammo_type =
      {
        category = ammo_category("mining-drone"),
        target_type = "entity",
        action =
        {
          type = "direct",
          action_delivery =
          {
            {
              type = "instant",
              target_effects =
              {
                {
                  type = "damage",
                  damage = {amount = 5 , type = damage_type("physical")}
                }
              }
            }
          }
        }
      },
      animation = base.animations[1].mining_with_tool
    },
    vision_distance = 100,
    has_belt_immunity = true,
    affected_by_tiles = true,
    movement_speed = 0.25 * random_height,
    distance_per_frame = 0.25 / random_height,
    pollution_to_join_attack = 1000000,
    --corpse = bot_name.."-corpse",
    run_animation = base.animations[1].running,
    rotation_speed = 0.05 / random_height,
    light =
    {
      {
        minimum_darkness = 0.3,
        intensity = 0.4,
        size = 15 * random_height,
        color = {r=1.0, g=1.0, b=1.0}
      },
      {
        type = "oriented",
        minimum_darkness = 0.3,
        picture =
        {
          filename = "__core__/graphics/light-cone.png",
          priority = "extra-high",
          flags = { "light" },
          scale = 2,
          width = 200,
          height = 200
        },
        shift = {0, -7 * random_height},
        size = 1 * random_height,
        intensity = 0.6,
        color = {r=1.0, g=1.0, b=1.0}
      }
    },
    running_sound_animation_positions = {5, 16},
    walking_sound = 
    {
      aggregation =
      {
        max_count = 2,
        remove = true
      },
      variations = data.raw.tile["grass-1"].walking_sound
    }
}

local path = table.deepcopy(data.raw.tile["green-refined-concrete"])
path.name = "ba-path"
path.minable = {
  mining_time = 0.1,
  result = "ba-item-path"
}
path.collision_mask = {"train-layer"}
path.tint = { r = 0.300, g = 0.300, b = 0.200,   a = 0.25 }

local path_item = {
    type = "item",
    name = "ba-item-path",
    place_as_tile =
    {
      result = "ba-path",
      condition_size = 1,
      condition = { "water-tile" }
    },
    icon = "__base__/graphics/icons/checked-green.png",
    tint = {r=0.49, g=0.49, b=0.49, a=0.2},
    icon_size = 64,
    icon_mipmaps = 4,
    -- pictures =
    -- {
    --     { size = 64, filename = "__canal-excavator-graphics__/graphics/icons/marker.png",   scale = 0.25, mipmap_count = 4 }
    -- },
    subgroup = "terrain",
    order = "c[landfill]-b[canal]",
    stack_size = 50
}

local pickup_text = table.deepcopy(data.raw["flying-text"]["flying-text"])
pickup_text.name = "ba-pickup-text"
pickup_text.speed = 0.025
pickup_text.time_to_live = 30
pickup_text.text_alignment = "center"
local dropoff_text = table.deepcopy(pickup_text)
dropoff_text.name = "ba-dropoff-text"
dropoff_text.speed = dropoff_text.speed * -1


data:extend{ worker, path, path_item, pickup_text, dropoff_text }

construction_template = require("data/construction-template")

data:extend(construction_template(1,1))
data:extend(construction_template(1,2))
data:extend(construction_template(2,1))
data:extend(construction_template(2,2))
data:extend(construction_template(2,3))
data:extend(construction_template(3,2))
data:extend(construction_template(3,3))
data:extend(construction_template(3,5))
data:extend(construction_template(4,4))
data:extend(construction_template(5,5))