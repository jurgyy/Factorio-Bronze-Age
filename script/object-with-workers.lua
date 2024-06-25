---@type WorkerDistribution
local worker_distribution = require("script/worker-distribution")

---@class ScriptObjectWithWorkers
---@field assigned_workers integer Current amount of workers available
---@field max_workers integer Maximum number of workers
---@field entity LuaEntity
object_with_worker = {}

---@param entity LuaEntity Target entity
---@param max_workers integer Maximum number of workers
---@return ScriptObjectWithWorkers
function object_with_worker.new(entity, max_workers)
    local data = {
        assigned_workers = 0,
        max_workers = max_workers,
        entity = entity
    }
    worker_distribution.add_building(data)
    return data
end

function object_with_worker.remove(data)
    worker_distribution.remove_building(data)
end

---@param amount integer? Amount of workers to add
---@return integer added The number of workers added
function object_with_worker:add_workers(amount)
    amount = amount or 1
    local old_worker_count = self.assigned_workers
    self.assigned_workers = math.min(self.assigned_workers + amount, self.max_workers)
    local added_workers = self.assigned_workers - old_worker_count
    return added_workers
end

return object_with_worker