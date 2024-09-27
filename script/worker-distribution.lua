local util = require("ba-util")
local priority_enum = require("script/worker-priority")

---@class WorkerDistribution
---@field buildings table<integer, ScriptObjectWithWorkers> t<unit_number, building_data>
---@field num_buildings integer
---@field population integer
---@field unemployed integer Unemployed number of unassigned workers
---@field last_pop integer Total population in the previous update
---@field last_num_buildings integer Total number of buildings in the previous update
local dist = {}
local dist_metatable = {__index = dist}

---@class WorkerDistributionScriptData
---@field distributions table<integer, WorkerDistribution> Maps path network id to a WorkerDistribution object
local script_data = {
    distributions = {},
}

---@param network_id integer
---@return WorkerDistribution
function dist.new(network_id)
    if script_data.distributions[network_id] then error("Network id already registered") end

    ---@type WorkerDistribution
    local distribution = {
        buildings = {},
        num_buildings = 0,
        population = 0,
        unemployed = 0,
        last_pop = 0,
        last_num_buildings = 0
    }
    setmetatable(distribution, dist_metatable)
    script_data.distributions[network_id] = distribution

    return distribution
end

---Add a building to the script data
---@param building_data ScriptObjectWithWorkers
---@param network_id integer
---@param recalculate boolean? Recalculate the network. Defaults to true. If false you should call the recalculate method for the network you modifed manually
function dist.add_building(building_data, network_id, recalculate)
    recalculate = recalculate == nil or recalculate

    local self = script_data.distributions[network_id]
    if not self then
        self = dist.new(network_id)
    end
    building_data.path_network_id = network_id
    self.buildings[building_data.entity.unit_number] = building_data
    self.num_buildings = self.num_buildings + 1
    if recalculate then
        self.recalculate(network_id)
    end
end

---Remove a building from the script data
---@param building_data ScriptObjectWithWorkers
---@param recalculate boolean? Recalculate the network. Defaults to true. If false you should call the recalculate method for the network you modifed manually
function dist.remove_building(building_data, recalculate)
    recalculate = recalculate == nil or recalculate

    local network_id = building_data.path_network_id
    if not network_id then return end
    
    building_data:reset_workers()
    
    local self = script_data.distributions[network_id]
    self.buildings[building_data.entity.unit_number] = nil
    self.num_buildings = self.num_buildings - 1
    if recalculate then
        self.recalculate(network_id)
    end
end

---Transfer all buildings in one network to another
---@param source_network integer
---@param destination_network integer
function dist.transfer_network(source_network, destination_network)
    local self = script_data.distributions[source_network]
    if not self then return end

    for _, building_data in pairs(self.buildings) do
        dist.remove_building(building_data, false)
        dist.add_building(building_data, destination_network, false)
    end

    dist.add_population(destination_network, self.population)
    self.population = 0
    dist.recalculate(source_network)
    dist.recalculate(destination_network)
end

---Add population to the surface
---@param network_id integer
---@param amount integer
function dist.add_population(network_id, amount)
    local self = script_data.distributions[network_id]
    if self then
        self.population = self.population + amount
    else
        self = dist.new(network_id)
        self.population = amount
    end
end

---@param pop integer
---@param amount integer
---@return integer
local function calculate_ratio(pop, amount)
    if amount ~= 0 then
        return math.min(1, pop / amount)
    end
    return 0
end

---@class WorkerDistributionRequiredPerPriority
---@field low integer
---@field medium integer
---@field high integer
---@field total integer

---Returns a table with the required amount of workers per priority and the total
---@return WorkerDistributionRequiredPerPriority priority
function dist:get_total_required()
    local high, medium, low = 0, 0, 0
    for _, b in pairs(self.buildings) do

        --local category = b:getCategory()
        local priority = priority_enum.Medium--priorityMap[category]

        if priority == priority_enum.Low then
            low = low + b.max_workers
        elseif priority == priority_enum.High then
            high = high + b.max_workers
        elseif priority == priority_enum.Medium then
            medium = medium + b.max_workers
        end

        ::continue::
    end

    return {
        low = low,
        medium = medium,
        high = high,
        total = high + medium + low
    }
end

---Recalculate the worker distribution of all buildings on a surface
---@param network_id integer
function dist.recalculate(network_id)
    local self = script_data.distributions[network_id] or dist.new(network_id)

    -- Check if the population, priority map, and active building count haven't changed
    local pop = self.population or 0
    -- if pop == self.last_pop and self.last_num_buildings == self.num_buildings then
    --     game.print("Population unchanged")
    --     return -- Avoid recalculating if nothing has changed
    -- end

    local pop_remaining = pop
    local buildings = self.buildings

    -- Synchronize access to the buildings
    local high, medium, low = 0, 0, 0
    for _, b in pairs(self.buildings) do
        --local category = b:getCategory()
        local priority = b.worker_priority

        if priority == priority_enum.Medium then
            medium = medium + b.max_workers
        elseif priority == priority_enum.High then
            high = high + b.max_workers
        elseif priority == priority_enum.Low then
            low = low + b.max_workers
        end
    end

    local total_needed = math.floor(high + medium + low)

    local priority_ratios = {
        [priority_enum.High] = calculate_ratio(pop, high),
        [priority_enum.Medium] = calculate_ratio(pop - high, medium),
        [priority_enum.Low] = calculate_ratio(pop - high - medium, low)
    }

    local bRatios = {}
    for unit_number, building in pairs(buildings) do
        -- Debug v
        local surface = building.entity.surface
        local x = building.entity.position.x
        local y = building.entity.position.y
        surface.create_entity{name = "still-text", position = {x, y}, text = network_id}
        -- Debug ^
        --local category = b:getCategory()
        local priority = priority_enum.Medium -- priorityMap[category]
        bRatios[unit_number] = math.floor(building.max_workers * priority_ratios[priority])
        building.assigned_workers = 0
    end

    while pop_remaining > pop - total_needed or pop_remaining == 0 do
        for unit_number, ratio in pairs(bRatios) do
            local b = buildings[unit_number]
            if pop_remaining <= 0 then
                break
            end

            local bPopMax = b.max_workers
            local bPop = b.assigned_workers

            if bPopMax > bPop and ratio >= bPop then
                pop_remaining = pop_remaining - 1
                b:add_workers(1)
            else
                bRatios[unit_number] = nil
            end
        end

        if pop_remaining <= 0 then
            break
        end
    end

    for unit_number, building in pairs(buildings) do
        building:on_workers_set()
    end

    game.print("Unemployed: " .. pop_remaining)
    self.unemployed = pop_remaining
    --lastActiveNbr = city:getActiveBuilding() -- Update the lastActiveNbr with the current active building count
    self.last_num_buildings = self.num_buildings
    self.last_pop = pop
    --lastPriorityMap = priorityMap
end

---Get the total number of workers given a network_id
---@param network_id integer
---@return integer
dist.get_total_workers = function(network_id)
    return script_data.distributions[network_id] and script_data.distributions[network_id].population or 0
end

---@param network_id integer
---@return WorkerDistribution?
dist.get_distribution = function(network_id)
    return script_data.distributions[network_id]
end

dist.events = {
    -- [defines.events.on_built_entity] = on_built_entity,
    -- [defines.events.on_robot_built_entity] = on_built_entity,
    -- [defines.events.script_raised_revive] = on_built_entity,
    -- [defines.events.script_raised_built] = on_built_entity,

    -- [defines.events.on_player_mined_entity] = on_entity_removed,
    -- [defines.events.on_robot_mined_entity] = on_entity_removed,

    -- [defines.events.on_entity_died] = on_entity_removed,
    -- [defines.events.script_raised_destroy] = on_entity_removed,

    --[defines.events.on_tick] = on_tick
}

dist.on_init = function()
    global.worker_distribution = global.worker_distribution or script_data
end

dist.on_load = function()
    script_data = global.worker_distribution or script_data
    for network_id, worker_distribution_data in pairs(script_data.distributions) do
        setmetatable(worker_distribution_data, dist_metatable)
    end
end

dist.on_configuration_changed = function()
    game.print("worker_distribution config changed")
    if not global.worker_distribution then
        global.worker_distribution = script_data
    end

    if not global.worker_distribution_targets then
        global.worker_distribution_targets = {}
    end
end

return dist