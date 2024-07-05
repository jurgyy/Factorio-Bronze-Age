local defines = nil

---@param name string Inserter prototype name 
---@return integer
local function calculate_inserter_workers(name)
    ---@type LuaEntityPrototype
    local inserter = game.entity_prototypes[name]
    return math.floor(inserter.max_energy_usage * 60 + 0.5)
end

local function get_defines()
    if defines then return defines end
    defines = {
        ["inserter"] = {
            max_workers = calculate_inserter_workers("inserter")
        }
    }
    return defines
end


return get_defines