local util = require("ba-util")

---@class WorkerDistribution
---@field buildings table<integer, ScriptObjectWithWorkers>
---@field num_buildings integer
---@field population integer
---@field unemployed integer Unemployed number of unassigned workers
---@field last_pop integer Total population in the previous update
---@field last_num_buildings integer Total number of buildings in the previous update
local dist = {}
local dist_metatable = {__index = dist}

---@class WorkerDistributionScriptData
---@field distributions table<integer, WorkerDistribution> Maps surface_index to a WorkerDistribution object
---@field population table<integer, integer> surface_index -> total population
local script_data = {
    distributions = {},
}

---@enum DistributionPriority
local Priority = {
    Low = 1,
    Medium = 2,
    High = 3
}

---@param surface_index integer Surface Index
---@return WorkerDistribution
function dist.new(surface_index)
    if script_data.distributions[surface_index] then error("Surface already registered") end

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
    script_data.distributions[surface_index] = distribution

    return distribution
end

---Add a building to the script data
---@param building_data ScriptObjectWithWorkers
function dist.add_building(building_data)
    local surface_index = building_data.entity.surface_index
    local self = script_data.distributions[surface_index]
    if not self then
        self = dist.new(surface_index)
    end
    self.buildings[building_data.entity.unit_number] = building_data
    self.num_buildings = self.num_buildings + 1
    self.recalculate(surface_index)
end

---Remove a building from the script data
---@param building_data ScriptObjectWithWorkers
function dist.remove_building(building_data)
    local surface_index = building_data.entity.surface_index
    local self = script_data.distributions[surface_index]

    self.buildings[building_data.entity.unit_number] = nil
    self.num_buildings = self.num_buildings - 1
    self.recalculate(surface_index)
end

---Add population to the surface
---@param surface_index integer
---@param amount integer
function dist.add_population(surface_index, amount)
    local self = script_data.distributions[surface_index]
    if self then
        self.population = self.population + amount
    else
        self = dist.new(surface_index)
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

---Recalculate the worker distribution of all buildings on a surface
---@param surface_index integer
function dist.recalculate(surface_index)
    local self = script_data.distributions[surface_index] or dist.new(surface_index)

    -- Check if the population, priority map, and active building count haven't changed
    local pop = self.population or 0
    if pop == self.last_pop and self.last_num_buildings == self.num_buildings then
        game.print("Population unchanged")
        return -- Avoid recalculating if nothing has changed
    end

    local pop_remaining = pop
    local buildings = self.buildings

    -- Synchronize access to the buildings
    local high, medium, low = 0, 0, 0
    for _, b in pairs(self.buildings) do

        --local category = b:getCategory()
        local priority = Priority.Medium--priorityMap[category]

        if priority == Priority.Low then
            low = low + b.max_workers
        elseif priority == Priority.High then
            high = high + b.max_workers
        elseif priority == Priority.Medium then
            medium = medium + b.max_workers
        end

        ::continue::
    end

    local total_needed = math.floor(high + medium + low)

    local priority_ratios = {
        [Priority.High] = calculate_ratio(pop, high),
        [Priority.Medium] = calculate_ratio(pop - high, medium),
        [Priority.Low] = calculate_ratio(pop - high - medium, low)
    }

    local bRatios = {}
    for unit_number, building in pairs(buildings) do
        --local category = b:getCategory()
        local priority = Priority.Medium -- priorityMap[category]
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

    game.print("Unemployed: " .. pop_remaining)
    self.unemployed = pop_remaining
    --lastActiveNbr = city:getActiveBuilding() -- Update the lastActiveNbr with the current active building count
    self.last_num_buildings = self.num_buildings
    self.last_pop = pop
    --lastPriorityMap = priorityMap
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
    for surface_index, worker_distribution_data in pairs(script_data.distributions) do
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