local defines = nil

---@param prototype LuaEntityPrototype Inserter prototype 
---@return integer?
local function calculate_inserter_workers(prototype)
    if not prototype.electric_energy_source_prototype then
        return
    end

    return math.floor(prototype.max_energy_usage * 60 + 0.5)
end

---@param prototype LuaEntityPrototype Non-inserter prototype 
---@return integer?
local function calculate_entity_workers(prototype)
    local energy_usage = prototype.energy_usage
    if not energy_usage then
        return
    end
    --local drain = prototype.electric_energy_source_prototype and prototype.electric_energy_source_prototype.drain or 0

    local workers = math.floor(energy_usage * 60 + 0.5)
    return workers
end

local excluded = {
    ["mining-depot"] = true, -- TODO remove once the dependancy on Mining-Drones is removed
    ["mining-camp"] = true,
    ["loggers-camp"] = true,
}

local function get_defines()
    if defines then return defines end
    defines = {}
    for name, prototype in pairs(game.entity_prototypes) do
        if excluded[name] then
            goto continue
        end

        local max_workers = nil

        if prototype.type == "inserter" then
            max_workers = calculate_inserter_workers(prototype)
        else
            max_workers = calculate_entity_workers(prototype)
        end

        if not max_workers then goto continue end
        
        defines[name] = {
            max_workers = max_workers
        }

        ::continue::
    end
    return defines
end


return get_defines