---@type WorkerDistribution
local worker_distribution = require("script/worker-distribution")
local priority_enum = require("script/worker-priority")
local util = require("ba-util")
local path_network = require("script/path-network")

---@class ScriptObjectWithWorkers
---@field assigned_workers integer Current amount of workers available
---@field max_workers integer Maximum number of workers
---@field entity LuaEntity
---@field path_network_id integer? Network in which this building is connected to (Can't be connected to multiple buildings)
---@field worker_priority DistributionPriority
object_with_worker = {
    assigned_workers = 0
}

local object_with_worker_metatable = {
    __index = object_with_worker
}


---@param entity LuaEntity? Target entity
---@param max_workers integer? Maximum number of workers
---@param o any? Data for the instance of the inheriting class
---@return ScriptObjectWithWorkers
function object_with_worker:new(entity, max_workers, o)
    o = o or {}
    setmetatable(o, object_with_worker_metatable)

    if entity then
        if not entity.unit_number then error("currently only entities with unit number are supported") end

        o.max_workers = max_workers
        o.entity = entity
        o.worker_priority = priority_enum.Medium
        --worker_distribution.add_building(o)
        local surface = entity.surface
        local tiles = util.get_path_tiles_around_entity(surface, entity)
        if tiles and tiles[1] then
            local position = tiles[1].position
            local node = path_network.get_node(surface.index, position.x, position.y)
            if not node then error("Tile not part of a network") end
            
            worker_distribution.add_building(o, node.id)
        end
    end

    return o
end

function object_with_worker:handle_deletion()
    worker_distribution.remove_building(self)
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

function object_with_worker:reset_workers()
    self.path_network_id = nil
    self.assigned_workers = 0
    self:on_workers_set()
end

---Should be called when assigned_workers is changed. Can be overloaded by derived class
function object_with_worker:on_workers_set()
end

---Set the priority of this building. Does not update network.
---@param priority DistributionPriority 
function object_with_worker:set_priority(priority)
    self.worker_priority = priority
end

return object_with_worker