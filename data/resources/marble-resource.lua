local sounds = require("__base__/prototypes/entity/sounds")

return {
    {
        name = "marble",
        order = "d",
        map_color = {0.8, 0.8, 0.8},
        tint = {0.8, 0.8, 0.8, 0.5},
        mining_time = 1,
        walking_sound = sounds.ore,
        mining_visualisation_tint = {r = 0.895, g = 0.965, b = 1.000, a = 1.000}, -- #e4f6ffff
    },
    {
        base_density = 10,
        regular_rq_factor_multiplier = 1.10,
        starting_rq_factor_multiplier = 1.5,
        candidate_spot_count = 22, -- To match 0.17.50 placement
    }
}