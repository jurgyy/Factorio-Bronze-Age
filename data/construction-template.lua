local data_util = require("__bronze-age__/data/data-util")

local hit_effects = require ("__base__.prototypes.entity.hit-effects")
local sounds = require("__base__/prototypes/entity/sounds")

local function get_construction_prototype(width, height)
    return {{
        type = "container",
        name = "construction-" .. width .. "x" .. height,
        icon = "__base__/graphics/icons/steel-chest.png",
        icon_size = 64, icon_mipmaps = 4,
        minable = { mining_time = 1 },
        max_health = 350,
        corpse = "steel-chest-remnants",
        collision_mask = {"layer-55"},
        dying_explosion = "steel-chest-explosion",
        open_sound = { filename = "__base__/sound/metallic-chest-open.ogg", volume=0.43 },
        close_sound = { filename = "__base__/sound/metallic-chest-close.ogg", volume = 0.43 },
        resistances = {{
            type = "impact",
            percent = 60
        }},
        collision_box = {{-(width/2) - 0.15, -(height/2) - 0.15}, {(width/2) - 0.15, (height/2) - 0.15}},
        selection_box = {{-(width/2), -(height/2)}, {(width/2), (height/2)}},
        damaged_trigger_effect = hit_effects.entity(),
        --fast_replaceable_group = "container",
        inventory_size = 12,
        vehicle_impact_sound = sounds.generic_impact,
        picture =
        {
            layers = {data_util.place_holder_sprite(width, height)}
        },
        -- circuit_wire_connection_point = circuit_connector_definitions["chest"].points,
        -- circuit_connector_sprites = circuit_connector_definitions["chest"].sprites,
        -- circuit_wire_max_distance = default_circuit_wire_max_distance
    }, {
        type = "item",
        name = "construction-" .. width .. "x" .. height,
        icon = "__base__/graphics/icons/steel-chest.png",
        icon_size = 64, icon_mipmaps = 4,
        subgroup = "storage",
        order = "a[items]-c[steel-chest]-"..width.."-"..height,
        place_result = "construction-" .. width .. "x" .. height,
        stack_size = 50
    }}
end

return get_construction_prototype
