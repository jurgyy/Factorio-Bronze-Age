local collision_util = require("collision-mask-util")
local camp_defines = require("shared/camp-defines")
local shared_util = require("shared/shared-util")

local function startswith(str, start)
    return string.sub(str, 1, string.len(start)) == start
end

local miner_ammo_category = function()
    local name = "mining-drone"-- TODO: "ba-miner-ammo-cat"
    if not data.raw["ammo-category"][name] then
      data:extend{{type = "ammo-category", name = name, localised_name = {name}}}
    end
    return name
end

local empty_rotated_animation = function()
    return
    {
      filename = "__base__/graphics/entity/ship-wreck/small-ship-wreck-a.png",
      width = 1,
      height= 1,
      direction_count = 1,
      animation_speed = 1
    }
end
  
local empty_attack_parameters = function()
    return
    {
      type = "projectile",
      ammo_category = "bullet",
      cooldown = 1,
      range = 0,
      ammo_type =
      {
        category = miner_ammo_category(),
        target_type = "entity",
        --action = {}
      },
      animation = empty_rotated_animation()
    }
end

local axe_mining_ore_trigger =
{
  type = "play-sound",
  sound =
  {
    aggregation =
    {
      max_count = 3,
      remove = true
    },
    variations =
    {
      {
        filename = "__core__/sound/axe-mining-ore-1.ogg",
        volume = 0.4
      },
      {
        filename = "__core__/sound/axe-mining-ore-2.ogg",
        volume = 0.4
      },
      {
        filename = "__core__/sound/axe-mining-ore-3.ogg",
        volume = 0.4
      },
      {
        filename = "__core__/sound/axe-mining-ore-4.ogg",
        volume = 0.4
      },
      {
        filename = "__core__/sound/axe-mining-ore-5.ogg",
        volume = 0.4
      }
    }
  }
}
local mining_wood_trigger =
{
  type = "play-sound",
  sound =
  {
    variations =
    {
      {
        filename = "__core__/sound/mining-wood-1.ogg",
        volume = 0.4
      },
      {
        filename = "__core__/sound/mining-wood-2.ogg",
        volume = 0.4
      }
    }
  }
}

---@param prototype CampSupportedEntityPrototypes
---@return data.Sound
local function get_sound(prototype)
    if prototype.type == "tree" then
        return mining_wood_trigger
    end
    if prototype.type == "resource" then
        return axe_mining_ore_trigger
    end
    error("Unknown type")
end

---@param resource CampSupportedEntityPrototypes
local make_resource_attack_proxy = function(resource)
    local attack_proxy =
    {
      type = "unit",
      name = shared_util.get_proxy_name(resource),
      icon = "__base__/graphics/icons/ship-wreck/small-ship-wreck.png",
      icon_size = 32,
      flags = {"placeable-neutral", "placeable-off-grid", "not-on-map", "not-in-kill-statistics", "not-repairable"},
      order = "zzzzzz",
      max_health = shared.mining_damage * 1000000,
      collision_box = {{-0.1, -0.1}, {0.1, 0.1}},
      collision_mask = {"colliding-with-tiles-only"},
      selection_box = nil,
      run_animation = empty_rotated_animation(),
      attack_parameters = empty_attack_parameters(),
      movement_speed = 0,
      distance_per_frame = 0,
      pollution_to_join_attack = 0,
      distraction_cooldown = 0,
      vision_distance = 0
    }
    
    local sound_enabled = true
    local damaged_trigger =
    {
      sound_enabled and get_sound(resource) or nil
    }
  
    local particle = resource.minable.mining_particle
    if particle then
      table.insert(damaged_trigger,
      {
        type = "create-particle",
        repeat_count = 3,
        particle_name = particle,
        entity_name = particle,
        initial_height = 0,
        speed_from_center = 0.025,
        speed_from_center_deviation = 0.025,
        initial_vertical_speed = 0.025,
        initial_vertical_speed_deviation = 0.025,
        offset_deviation = resource.selection_box
      })
      attack_proxy.dying_trigger_effect =
      {
        type = "create-particle",
        repeat_count = 5,
        particle_name = particle,
        entity_name = particle,
        initial_height = 0,
        speed_from_center = 0.045,
        speed_from_center_deviation = 0.035,
        initial_vertical_speed = 0.045,
        initial_vertical_speed_deviation = 0.035,
        offset_deviation = resource.selection_box
      }
    end
  
    if next(damaged_trigger) then
      attack_proxy.damaged_trigger_effect = damaged_trigger
    end
  
    data:extend{attack_proxy}
  
end

collisions = {}

for type in pairs(defines.prototypes.entity) do
    for _, prototype in pairs(data.raw[type]) do
        local box = prototype.collision_box
        if not (startswith(prototype.name, "construction-")) and box then
            local width = math.ceil(box[2][1] - box[1][1])
            local height = math.ceil(box[2][2] - box[1][2])
            local index = width .. "," .. height
            if not collisions[index] then
                collisions[index] = {}
            end
            table.insert(collisions[index], prototype.name)
        end

        if prototype.minable then
            ---@cast prototype data.EntityPrototype|data.TilePrototype
            local recipe = data.raw.recipe[prototype.minable.result]
            if recipe and (recipe.ingredients or recipe.normal) then
                local ingredients = (recipe.ingredients or recipe.normal.ingredients)
                local multiplier = 1
                if prototype.name == "curved-rail" then
                    multiplier = 4
                end
                local results = {}
                if recipe.result_count and recipe.result_count > 1 then
                    log("Modifying the result_count for " .. recipe.name .. " from " .. recipe.result_count .. " to 1")
                    recipe.result_count = 1
                end
                for _, ingredient in ipairs(ingredients) do
                    if ingredient.type ~= "fluid" then
                        table.insert(results, {
                            type = "item",
                            name = ingredient[1],
                            amount = ingredient[2] * multiplier
                        })
                    else
                        log(prototype.name .. " Skipping fluid ingredient")
                    end
                end
                prototype.minable = {
                    mining_time = prototype.minable.mining_time,
                    result = nil,
                    results = results
                }
            else
                log("No recipe for " .. prototype.name)
            end
        end
    end
end

for shape, prototypes in pairs(collisions) do
    log("Shape " .. shape .. ": " .. table.concat(prototypes, ", "))
end


local worker = data.raw["unit"]["mining-drone"]
local worker_mask = table.deepcopy(worker.collision_mask)
collision_util.remove_layer(worker_mask, "doodad-layer")

for name, worker_def in pairs(camp_defines.workers) do
    local camp_worker = table.deepcopy(worker)
    camp_worker.name = name
    camp_worker.localised_name = nil
    camp_worker.localised_description = nil
    camp_worker.attack_parameters.range = worker_def.range
    camp_worker.render_layer = "object"
    data:extend{camp_worker}
end

for _, tree in pairs(data.raw["tree"]) do
    if worker_mask then
        for _, layer in pairs(worker_mask) do
            if tree then
                log("Removing layer " .. layer .. " from collision mask of " .. tree.name)
                collision_util.remove_layer(tree.collision_mask, layer)
            end
        end
    end
end

for camp_name, camp in pairs(camp_defines.camps) do
    if worker_mask then
        for _, layer in pairs(worker_mask) do
            local mining_camp = data.raw["assembling-machine"][camp_name]
            if mining_camp then
                log("Removing layer " .. layer .. " from collision mask of " .. mining_camp.name)
                collision_util.remove_layer(mining_camp.collision_mask, layer)
            end
        end
    end

    for name, resource_name in pairs(camp.recipes) do
        local resource_item = data.raw.item[resource_name]
        
        data:extend{{
            type = "recipe",
            name = name,
            icon = resource_item.icon,
            icon_size = resource_item.icon_size,
            icons = resource_item.icons,
            icon_mipmaps = resource_item.icon_mipmaps,
            ingredients = {
                {type = "item", name = camp.worker_name, amount = 1}
            },
            results = {{type = "item", name = resource_name, amount = 0, show_details_in_recipe_tooltip = false}},
            category = camp_defines.resources[resource_name].category,
            subgroup = "extraction-machine",
            --overload_multiplier = 100,
            hide_from_player_crafting = true,
            main_product = "",
            allow_decomposition = false,
            allow_as_intermediate = false,
            allow_intermediates = true,
            order = "zzzzz",
            allow_inserter_overload = false,
            energy_required = 1.166
        }}
    end
end

for resource_name, define in pairs(camp_defines.resources) do
    local entity
    if define.type == "tree" then
        _, entity = next(data.raw["tree"])
    elseif define.type == "resource" then
        entity = data.raw["resource"][resource_name]
    end
    if not entity then error("No entity") end
    make_resource_attack_proxy(entity)
end