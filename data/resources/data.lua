local data_util = require("__bronze-age__/data/data-util")
local root = data_util.data_root .. "resources/"

--local noise = require("noise")
--local tne = noise.to_noise_expression
local resource_autoplace = require("resource-autoplace")
local sounds = require("__base__/prototypes/entity/sounds")


---@param resource_parameters table
---@param autoplace_parameters table
---@param initizalize boolean?
---@return data.ResourceEntityPrototype
local function resource(resource_parameters, autoplace_parameters, initizalize)
    if initizalize ~= nil then
        resource_autoplace.initialize_patch_set("marble", initizalize)
    end

    if coverage == nil then coverage = 0.02 end
    
    ---@type data.ResourceEntityPrototype
    local entity = {
        type = "resource",
        name = resource_parameters.name,
        icon = data_util.icons_root .. resource_parameters.name .. ".png",
        icon_size = 64,
        icon_mipmaps = 4,
        flags = {"placeable-neutral"},
        order="a-b-"..resource_parameters.order,
        tree_removal_probability = 0.9,
        tree_removal_max_distance = 32 * 32,
        minable =
        {
            mining_particle = "iron-ore-particle",
            mining_time = resource_parameters.mining_time,
            result = resource_parameters.name
        },
        walking_sound = resource_parameters.walking_sound,
        collision_box = {{-0.1, -0.1}, {0.1, 0.1}},
        selection_box = {{-0.5, -0.5}, {0.5, 0.5}},
        -- autoplace = autoplace_settings(name, order, coverage),
        autoplace = resource_autoplace.resource_autoplace_settings
        {
            name = resource_parameters.name,
            order = resource_parameters.order,
            base_density = autoplace_parameters.base_density,
            has_starting_area_placement = true,
            regular_rq_factor_multiplier = autoplace_parameters.regular_rq_factor_multiplier,
            starting_rq_factor_multiplier = autoplace_parameters.starting_rq_factor_multiplier,
            candidate_spot_count = autoplace_parameters.candidate_spot_count
        },
        stage_counts = {15000, 9500, 5500, 2900, 1300, 400, 150, 80},
        stages =
        {
            sheet =
            {
                filename = "__base__/graphics/entity/iron-ore/iron-ore.png",
                priority = "extra-high",
                size = 64,
                frame_count = 8,
                variation_count = 8,
                tint = resource_parameters.tint,
                hr_version =
                {
                    filename = "__base__/graphics/entity/iron-ore/hr-iron-ore.png",
                    priority = "extra-high",
                    size = 128,
                    frame_count = 8,
                    variation_count = 8,
                    scale = 0.5,
                    tint = resource_parameters.tint,
                }
            }
        },
        map_color = resource_parameters.map_color,
        mining_visualisation_tint = resource_parameters.mining_visualisation_tint
    }
    return entity
end

data.raw["resource"]["iron-ore"].autoplace = resource_autoplace.resource_autoplace_settings
{
    name = "iron-ore",
    order = "b",
    base_density = 1, -- From 10
    has_starting_area_placement = false,
    regular_rq_factor_multiplier = 1.10,
    regular_blob_amplitude_multiplier = 0.5, -- new
    --candidate_spot_count = 22,
    base_spots_per_km2 = 0.75 -- new
}

data.raw["resource"]["coal"].autoplace = resource_autoplace.resource_autoplace_settings
{
    name = "coal",
    order = "b",
    base_density = 2, -- From 8,
    has_starting_area_placement = false,
    regular_rq_factor_multiplier = 1.1,
    regular_blob_amplitude_multiplier = 0.75, -- new default is 1
    base_spots_per_km2 = 3.5 -- new default is 2.5
}

-- Remove resources from the world generation and the sliders in the menu
local removed_resources = {"uranium-ore", "crude-oil"}
for _, resource_name in pairs(removed_resources) do
    data.raw["resource"][resource_name] = nil
    data.raw["autoplace-control"][resource_name] = nil
    data.raw["map-gen-presets"]["default"]["rail-world"].basic_settings.autoplace_controls[resource_name] = nil
    data.raw["map-gen-presets"]["default"]["ribbon-world"].basic_settings.autoplace_controls[resource_name] = nil
    data.raw["map-gen-presets"]["default"]["rich-resources"].basic_settings.autoplace_controls[resource_name] = nil
end

local marble = require(root .. "marble-resource")
local clay = require(root .. "clay-resource")

data:extend{
    require(root .. "marble-autoplace-control"),
    require(root .. "clay-autoplace-control"),
    resource(marble[1], marble[2], true),
    resource(clay[1], clay[2], true),
}