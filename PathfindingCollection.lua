local util = require("ba-util")

local pathfinding_collection = {}
pathfinding_collection.__index = pathfinding_collection

---@alias PathfindingRequests table<uint, Path>

---@class Path
---@field start MapPosition Start point
---@field goal MapPosition End point
---@field amount integer? Optional Path weight. A PathfindingCollection uses this if multiple paths are requested with a total weight. Defaults to 1
---@field start_entity LuaEntity? Optional entity that is required to be valid at the start
---@field collection PathfindingCollection Parent collection containing this path

---@class PathfindingCollection
---@field surface_index integer Surface index for the pathfinder
---@field unit_prototype LuaEntityPrototype prototype of the entity that has to walk the path
---@field goal_positions MapPosition[] Array of all positions that are valid for reaching the goal
---@field goal_entity LuaEntity Entity that requests the item
---@field to_be_checked table<integer, Path[]> Table that maps a start entity unit_number to an array of all possible Paths between it and the goal
---@field item_name string Name of the item requested
---@field total_amount integer? Total minimum amount of weight requested for if multiple paths. Defaults to 1
---@field private success_amount integer Counter to keep track of the amount of weight already passed
---@field add_path fun(Path)
---@field add_paths_from_entity fun(LuaEntity, integer)
---@field request_path fun(Path)
---@field path_found_finished fun(Path)
---@field request_next fun()
--@field private successes integer[]

---Returns a new PathfindingCollection object
---@param surface_index integer
---@param item_name string
---@param total_amount integer
---@param unit_prototype LuaEntityPrototype prototype of the entity that has to walk the path 
---@param goal_entity LuaEntity Target entity for the pathfinding
---@return PathfindingCollection?
function pathfinding_collection.new(surface_index, item_name, total_amount, unit_prototype, goal_entity)
    --[[@type PathfindingCollection]]
    local self = setmetatable({}, pathfinding_collection)
    local goal_positions = util.get_path_sets_around(goal_entity.surface, goal_entity.bounding_box)
    if not goal_positions or not goal_positions[1] then
        util.print("Target not near path")
        return
    end

    self.surface_index = surface_index
    self.unit_prototype = unit_prototype
    self.goal_positions = goal_positions
    self.goal_entity = goal_entity
    self.item_name = item_name
    self.total_amount = total_amount
    self.to_be_checked = {}
    self.success_amount = 0

    return self
end

---Requests the collection's surface for a path and stores the request's uid in global.pathfinding_requests.
---Only intended to call from outside the class if a request has failed with try_again_later
---@param path Path Path to request
---@return integer Uid for the 
function pathfinding_collection:request_path(path)
    local uid = game.surfaces[self.surface_index].request_path {
        bounding_box = self.unit_prototype.collision_box,
        collision_mask = self.unit_prototype.collision_mask,
        start = path.start,
        goal = path.goal,
        force = game.players[1].force -- TODO
    }
    global.pathfinding_requests[uid] = path
    return uid
end

---Add a path to be checked
---@param from_entity LuaEntity
---@param path Path
function pathfinding_collection:add_path(from_entity, path)
    if not self.to_be_checked[from_entity.unit_number] then
        self.to_be_checked[from_entity.unit_number] = {}
    end

    table.insert(self.to_be_checked[from_entity.unit_number], path)
end

---comments
---@param from_entity LuaEntity
---@param amount integer
function pathfinding_collection:add_paths_from_entity(from_entity, amount)
    local from_positions = util.get_path_sets_around(from_entity.surface, from_entity.bounding_box)

    local ds = global.tiles_disjoint_sets[self.surface_index]

    for _, from in ipairs(from_positions) do
        for _, to in ipairs(self.goal_positions) do
            if ds then
                if ds:isConnected(from, to) then
                    util.print("Connected according to DisjointSet")
                    self:add_path(from_entity, {
                        start = from,
                        goal = to,
                        amount = amount,
                        start_entity = from_entity,
                        collection = self
                    })
                else
                    util.print("Not connected according to DisjointSet, not adding path")
                end
            else
                util.print("Added path without using DisjointSet")
                self:add_path(from_entity, {
                    start = from,
                    goal = to,
                    amount = amount,
                    start_entity = from_entity,
                    collection = self
                })
            end
        end
    end
end

function pathfinding_collection:request_next()
    local index, paths = next(self.to_be_checked, nil)
    if not paths or not paths[1] then
        util.print("All paths requested")
        return nil
    end
    
    local path = table.remove(paths, 1)
    if #paths == 0 then
        self.to_be_checked[index] = nil
    end

    return self:request_path(path)
end

---Notify the collection that a path request has found a path. 
---@param path Path
---@return boolean Done The collection has reached or exceeded its target weight
function pathfinding_collection:path_found_finished(path)
    -- Don't pathfind the other possible paths from this path's start to the goal
    self.to_be_checked[path.start_entity.unit_number] = nil

    -- Add the path's weight to the total
    self.success_amount = self.success_amount + path.amount
    return self.success_amount >= self.total_amount
end

return pathfinding_collection