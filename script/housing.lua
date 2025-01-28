local util = require("ba-util")
local path_network = require("script/path-network")

---@type HousingDefine[]
local housing_defines = require("shared/housing-defines")

---@type WorkerDistribution
local worker_distribution = require("script/worker-distribution")

---@class HousingData
---@field id integer
---@field surface_index integer
---@field entity LuaEntity
---@field define HousingDefine Define for the current housing level
---@field network_id integer? Path network id
local housing = {}
local housing_metatable = {__index = housing}

---@class HousingScriptData
---@field houses table<integer, HousingData>
local script_data = {
    houses = {},
}

---Returns the first tile node surrounding the housing_data entity
---@param housing_data HousingData
---@return PathNode?
local function get_first_path_node(housing_data)
    local entity = housing_data.entity
    local surrounding_box = entity.prototype.collision_box
    surrounding_box.left_top.x = entity.position.x + surrounding_box.left_top.x - 1
    surrounding_box.left_top.y = entity.position.y + surrounding_box.left_top.y - 1
    surrounding_box.right_bottom.x = entity.position.x + surrounding_box.right_bottom.x + 1
    surrounding_box.right_bottom.y = entity.position.y + surrounding_box.right_bottom.y + 1

    local tiles = entity.surface.find_tiles_filtered {
        area = surrounding_box,
        name = "ba-path" -- TODO more than one and dynamically?
    }
    local _, tile = next(tiles)
    if not tile then
        game.print("Not near tiles")
        return
    end

    -- TODO: rounding?
    local node = path_network.get_node(housing_data.surface_index, tile.position.x, tile.position.y)
    if not node then
        util.highlight_position(game.surfaces[housing_data.surface_index], tile.position, nil, true)
        game.print("No node at " .. tile.position.x .. ", " .. tile.position.y)
        return
    end
    return node
end

---Add housing to path network without checking anything
---@param housing_data HousingData
---@param network_id integer
local function add_to_network_unsafe(housing_data, network_id)
    housing_data.network_id = network_id
    worker_distribution.add_population(network_id, housing_data.define.workers)
    worker_distribution.recalculate(network_id)
end

---Add housing to the script_data
---@param housing_data HousingData
---@param update_workers boolean? Update the workers. Defaults to true
local function add_housing(housing_data, update_workers)
    local node = get_first_path_node(housing_data)
    if not node then return end

    path_network.add_housing(node.id, housing_data)
end

---@param entity LuaEntity
---@param network_id integer
local function add_to_network(entity, network_id)
    local id = script.register_on_object_destroyed(entity)
    local housing_data = script_data.houses[id]
    if not housing_data then error("No housing data for entity") end
    if housing_data.network_id then return end

    add_to_network_unsafe(housing_data, network_id)
end

---Remove housing from the script_data
---@param housing_data HousingData
---@param update_workers boolean? Update the workers. Defaults to true
local function remove_housing(housing_data, update_workers)
    script_data.houses[housing_data.id] = nil

    if (update_workers == nil or update_workers) and housing_data.network_id then
        worker_distribution.add_population(housing_data.network_id, -housing_data.define.workers)
        worker_distribution.recalculate(housing_data.network_id)
    end
end

---Swap the entity from a given housing_data object and update the script_data
---@param housing_data HousingData
---@param new_entity LuaEntity
local function swap_entity(housing_data, new_entity)
    local prev_workers = housing_data.define.workers
    remove_housing(housing_data, false)
    
    housing_data.entity = new_entity
    housing_data.id = new_entity.unit_number
    housing_data.define = housing_defines[new_entity.name]
    
    if not housing_data.define then error("Unknown housing " .. new_entity.name) end

    local delta_workers = housing_data.define.workers - prev_workers
    add_housing(housing_data, false)

    if housing_data.network_id then
        worker_distribution.add_population(housing_data.network_id, delta_workers)
        worker_distribution.recalculate(housing_data.network_id)
    end
end


---@param housing_entity LuaEntity
---@return HousingData
function housing.new(housing_entity)
    ---@type HousingData
    ---@diagnostic disable-next-line: missing-fields
    local housing_data = {
        id = script.register_on_object_destroyed(housing_entity),
        surface_index = housing_entity.surface_index,
        entity = housing_entity,
        define = housing_defines[housing_entity.name]
    }
    if not housing_data.define then error("Unknown housing type " .. housing_entity.name) end

    add_housing(housing_data)
    setmetatable(housing_data, housing_metatable)
    housing_entity.active = false
    return housing_data
end

function housing:handle_deletion()
    remove_housing(self)
end

---Swap the housing from one
---@param housing_data any
---@param new_entity_name any
local function swap_housing(housing_data, new_entity_name)
    if not housing_data.entity.valid then error("Current entity not valid") end
    local surface = housing_data.surface
    local position = housing_data.entity.position
    housing_data.entity.destroy()

    local upgrade = surface.create_entity {
        name = new_entity_name,
        position = position
    }

    if not upgrade or not upgrade.valid then error("Couldn't spawn housing " .. new_entity_name) end

    swap_entity(housing_data, upgrade)
end

---Try to upgrade the housing to the next tier if a next tier is defined
function housing:try_upgrade()
    local upgrade = self.define.upgrades_to
    if not housing_defines[upgrade] then return end
    swap_housing(self, upgrade)
end

---Try to downgrade the housing to the previous tier if a previous tier is defined
function housing:try_downgrade()
    local downgrade = self.define.upgrades_from
    if not housing_defines[downgrade] then return end
    swap_housing(self, downgrade)
end

function housing:update()

end

---@param event EventData.on_built_entity|EventData.on_robot_built_entity|EventData.script_raised_revive|EventData.script_raised_built
local function on_built_entity(event)
    local entity = event.entity or event.entity
    if not (entity and entity.valid) then return end
    if not housing_defines[entity.name] then return end
    housing.new(entity)
end

---@param event EventData.on_object_destroyed --EventData.on_player_mined_entity|EventData.on_robot_mined_entity|EventData.on_entity_died|EventData.script_raised_destroy
local on_entity_removed = function(event)
    local unit_number = event.registration_number --[[@as integer?]]
    if not unit_number then
        return
    end
  
    local housing_data = script_data.houses[unit_number]
    if not housing_data then return end
    
    housing_data:handle_deletion()
end

---@param event EventData.on_tick
local on_tick = function(event)
    local do_update = event.tick % 60 == 0
    if do_update then
        for unit_number, housing_data in pairs (script_data.houses) do
            if not (housing_data.entity.valid) then
                housing_data:handle_deletion()
                script_data[unit_number] = nil
            else
                housing_data:update()
            end
        end
    end
end

local lib = {}

lib.add_to_network = add_to_network

lib.events = {
    [defines.events.on_built_entity] = on_built_entity,
    [defines.events.on_robot_built_entity] = on_built_entity,
    [defines.events.script_raised_revive] = on_built_entity,
    [defines.events.script_raised_built] = on_built_entity,

    [defines.events.on_object_destroyed] = on_entity_removed,

    --[defines.events.on_tick] = on_tick
}

lib.on_init = function()
    storage.housing = storage.housing or script_data
end

lib.on_load = function()
    script_data = storage.housing or script_data
    for unit_number, housing_data in pairs(script_data.houses) do
        setmetatable(housing_data, housing_metatable)
    end
end

lib.on_configuration_changed = function()
    game.print("housing config changed")
    if not storage.housing then
        storage.housing = script_data
    end
end

return lib