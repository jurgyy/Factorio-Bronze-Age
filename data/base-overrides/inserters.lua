local inserters = data.raw["inserter"]

---Set the energy correctly for a given number of workers of a inserter
---@param name string
---@param amount integer
local function set_workers_energy(name, amount)
    local inserter = inserters[name]
    
    inserter.energy_per_movement = "0J"
    inserter.energy_per_rotation = tostring(amount / (inserter.rotation_speed * 60)) .. "J"
    inserter.energy_source.drain = nil
end

set_workers_energy("inserter", 1)
set_workers_energy("long-handed-inserter", 5)
set_workers_energy("fast-inserter", 10)
set_workers_energy("filter-inserter", 12)
set_workers_energy("stack-inserter", 20)
set_workers_energy("stack-filter-inserter", 20)