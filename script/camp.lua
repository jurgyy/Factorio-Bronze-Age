-- Largely copied from Mining Drones by Klonan

local util = require("ba-util")

---@type CampDefines
local camp_defines = require("__bronze-age__/shared/camp-defines")
local camp_worker = require("script/camp-worker")

---@class CampData
---@field entity LuaEntity Camp building entity
---@field workers table<integer, boolean> Worker's unit_numbers associated with this camp
---@field potential integer[] Index of the potential resources for CampScriptData.targeted_resources ordered by distance (closest last)
---@field recent table<integer, boolean> Idk
---@field mined_any boolean? Set to true when first ordering a worker. Only set false afterwards when all work completed
---@field path_requests table<integer, LuaEntity> Map for the path request uid to the target entity
---@field entity_name string Name of the camp
---@field surface_index integer Surface index of the camp
---@field force_index integer Force index of the camp
---@field unit_number integer Unit number of the camp
---@field target_resource_name string? Prototype name of the entity being targeted
---@field target_carry_count integer? How much of the target resource can a worker haul in one go
---@field defines CampDefinesCamp Prototype and script data about the camp type
local camp = {}
local camp_metatable = {__index = camp}

---@class TargetedResource
---@field entity LuaEntity The resource entity
---@field camps table<integer, boolean> Map of camp unit_numbers targeting this entity when true
---@field max_mining integer The number of workers that can work this entity at the same time. It's ceil(entity-radius^2)
---@field mining integer The number of workers working this resource

---@class CampScriptData
---@field camps CampData[] All the camp entities
---@field path_requests table<integer, CampData> Map for the path request uid to the target entity
---@field targeted_resources table<integer, table<integer, TargetedResource>> Per surface index, the resources currently targeted by a camp indexed by a unique number per resource entity
---@field request_queue table<integer, LuaEntity[]> Per camp the outstanding requests to mine a resource indexed by the camp's unit_number
local script_data =
{
    camps = {},
    path_requests = {},
    targeted_resources = {},
    request_queue = {},
    big_migration = true,
}

local path_queue_rate = 13

local function area(position, radius)
    return {{position.x - radius, position.y - radius},{position.x + radius, position.y + radius}}
end
  

---Get a camp from the script_data given its unit_number
---@param unit_number integer
---@return CampData?
local function get_camp(unit_number)
    return script_data.camps[unit_number]
end

---Overwrite camp_worker's get_mining_camp method
camp_worker.get_mining_camp = get_camp

-- The offset for the camp's drop position relative to its center
function camp:get_drop_offset()
    return {0, 0}
end

--- Add a new camp entity to the script_data
---@param camp_data CampData
local add_camp = function(camp_data)
    script_data.camps[camp_data.unit_number] = camp_data
end

---Initialize a new camp
---@param camp_entity LuaEntity The new camp entity
---@return CampData camp_data The script data for the new camp
function camp.new(camp_entity)
    ---@type CampData
    local camp_data = {
        entity = camp_entity,
        workers = {},
        potential = {},
        recent = {},
        path_requests = {},
        entity_name = camp_entity.name,
        surface_index = camp_entity.surface.index,
        force_index = camp_entity.force.index,
        unit_number = camp_entity.unit_number,
        defines = camp_defines.camps[camp_entity.name]
    }

    setmetatable(camp_data, camp_metatable)
    if not script_data.targeted_resources[camp_data.surface_index] then
        script_data.targeted_resources[camp_data.surface_index] = {}
    end

    camp:add_box()

    add_camp(camp_data)

    camp_entity.active = false

    return camp_data
end

---@param event EventData.on_built_entity|EventData.on_robot_built_entity|EventData.script_raised_revive|EventData.script_raised_built
local on_built_entity = function(event)
    local entity = event.entity or event.created_entity
    if not (entity and entity.valid) then return end
  
    if camp_defines.camps[entity.name] == nil then return end
  
    camp.new(entity)
end

function camp:add_box()

end

---Get the dropoff position for workers
---@return MapPosition
function camp:get_drop_position()
    local offset = self:get_drop_offset()
    local position = self.entity.position
    position.x = position.x + offset[1]
    position.y = position.y + offset[2]
    return position
end

---Get the worker's speed. Currently a fixed value but might introduce some variance later
---@return number
function camp:get_worker_speed()
    return 0.05
end

local direction_names =
{
  [0] = "north",
  [2] = "east",
  [4] = "south",
  [6] = "west"
}

---Spawn a new worker
---@return CampWorkerData? worker The worker entity or nil if the worker can't be created
function camp:spawn_worker()
    if self:get_active_worker_count() >= self:get_worker_item_count() then
      return
    end
  
    local worker_name = self.defines.worker_name
  
    local camp_entity = self.entity
    local spawn_entity_data =
    {
      name = worker_name,
      position = self.entity.position,
      force = camp_entity.force,
      create_build_effect_smoke = false
    }
  
    local surface = camp_entity.surface
    if not surface.can_place_entity(spawn_entity_data) then return end
  
    local unit = surface.create_entity(spawn_entity_data)
    if not unit then return end
  
    unit.orientation = (camp_entity.direction / 8)
    --unit.ai_settings.do_separation = false
  
    --self:get_drone_inventory().remove({name = names.drone_name, count = 1})
  
  
    local worker = camp_worker.new(unit, self)
    self.workers[unit.unit_number] = true
  
    return worker
end

--- Call the cancel_command on all workers and then remove the camp's workers table
function camp:cancel_all_orders()
    if not self.workers then return end

    for unit_number, bool in pairs(self.workers) do
        local worker = camp_worker.get_worker(unit_number)
        if worker then
            worker:cancel_command()
        end
    end
    self.workers = {}
end

---Get the resource associated with the selected recipe
---@return string? resource_name
function camp:get_target_resource_name()
    local recipe = self.entity.get_recipe()
    if not recipe then return end

    local recipe_data = self.defines.recipes[recipe.name]
    if not recipe_data then return end

    return recipe_data.resource
end

---Get the carry count of the target resource
---TODO optimize with get_target_resource_name()
---@return integer?
function camp:get_target_carry_count()
    local recipe = self.entity.get_recipe()
    if not recipe then return end

    local recipe_data = self.defines.recipes[recipe.name]
    if not recipe_data then return end

    return recipe_data.carry_count
end

---Camp recipe has changed. Clear all paths, cancel all orders and find new resources to mine
function camp:target_name_changed()
    self.target_resource_name = self:get_target_resource_name()
    self.target_carry_count = self:get_target_carry_count()
    
    self:clear_path_requests()
    self:cancel_all_orders()
  
    self:find_potential_targets()
end

--- Function that gets called on_tick cycle
function camp:update()
    local camp_entity = self.entity
    if not (camp_entity and camp_entity.valid) then return end
  
    local resource_name = self:get_target_resource_name()
    if resource_name ~= self.target_resource_name then
        --TODO get_target_resource_name() gets called twice
        self:target_name_changed()
        return
    end
  
    if not resource_name then return end
  
    if not self:has_mining_targets() then
        --Nothing to mine, nothing to do...

        if next(self.workers) then
            --Workers are still mining, so they can be holding the targets.
            return
        end

        if not self.mined_any then
            -- Last time we rescanned, and we didn't mine anything, so lets give up.
            return
        end

        self:find_potential_targets()
    end

    self:try_to_mine_targets()
end

-- ???
local target_amount_per_drone = 100
local max_target_amount = 65000 / 250

---How many workers should be spawned
---@param extra boolean? Add one extra to the amount of already active number of workers
---@return integer amount Number of workers to spawn
function camp:get_should_spawn_worker_count(extra)
    -- Number of worker items in the camp
    local max_workers = self:get_worker_item_count()

    local active = (self:get_active_worker_count() - (extra and 1 or 0))

    if active >= max_workers then return 0 end

    -- ???
    local current_target_item_count = math.min(target_amount_per_drone , max_target_amount) * max_workers
    local current_item_count = self:get_max_output_amount()

    -- ???
    local ratio = 1 - ((current_item_count / current_target_item_count) ^ 2)

    return math.ceil(ratio * max_workers) - active
end

function camp:say(text)
    self.entity.surface.create_entity{name = "flying-text", position = self.entity.position, text = text}
end

function camp:try_to_mine_targets()
    local max_workers = self:get_worker_item_count()
    local active = self:get_active_worker_count()
  
    if active >= max_workers then
        return
    end
  
    local should_spawn_count = self:get_should_spawn_worker_count()
  
    if should_spawn_count <= 0 then return end
  
    for k = 1, should_spawn_count do
        local entity = self:find_entity_to_mine()
        if not entity then return end
        self:attempt_to_mine(entity)
    end
end

--- Are there elements in self.recent or self.potential
---@return boolean
function camp:has_mining_targets()
    return next(self.recent) == true or next(self.potential) ~= nil
end

---Get the number of workers inserted in the camp
---@return integer
function camp:get_worker_item_count()
    return self.entity.get_item_count(self.defines.worker_name)
end

---Register an on_entity_destroyed event just to get a unique value for an entity
---@param entity LuaEntity
---@return integer
local unique_index = function(entity)
    return script.register_on_entity_destroyed(entity)
end

local directions =
{
  [defines.direction.north] = {0, -1},
  [defines.direction.south] = {0, 1},
  [defines.direction.east] = {1, 0},
  [defines.direction.west] = {-1, 0},
}

---Get the camp's mining area bounding box
---@return BoundingBox
function camp:get_mining_area()
    local origin = self.entity.position
    local radius = self.defines.mining_radius
    local offset = self.defines.mining_radius_offset

    local direction = directions[self.entity.direction]
    local center_offset = {direction[1] * (radius + offset + 0.5), direction[2] * (radius + offset + 0.5)}

    origin.x = origin.x + center_offset[1]
    origin.y = origin.y + center_offset[2]
    return area(origin, radius)
end

---Take an array of entities and sort them by distance (closest last) and return an array of the entities' index in CampScriptData.TargetedResource
---@param entities LuaEntity[]
---@return integer[] sortedTargetedResourceIndices Entity indices of CampScriptData.TargetedResource[surface index] sorted by distance 
function camp:sort_by_distance(entities)
    local origin = self.entity.position
    local x, y = origin.x, origin.y
    
    local distance = function(position)
        return ((x - position.x) ^ 2 + (y - position.y) ^ 2)
    end
        
    local targeted_resources = script_data.targeted_resources[self.surface_index]
        
    ---@diagnostic disable:missing-fields, undefined-field
    for k, entity in pairs (entities) do
        local index = unique_index(entity)
        if not targeted_resources[index] then
            targeted_resources[index] = {
                entity = entity,
                camps = {},
                max_mining = math.ceil(entity.get_radius() ^ 2),
                mining = 0
            }
        end
        entities[k] = {distance = distance(entity.position), index = index}
    end
    
    table.sort(entities, function (k1, k2) return k1.distance > k2.distance end )
    
    for k = 1, #entities do
        entities[k] = entities[k].index
    end
    ---@diagnostic enable:missing-fields, undefined-field
    return entities
end

---Find potential resources to mine, sort them and store the result in self.potential
function camp:find_potential_targets()
    local target_name = self.target_resource_name
    if not target_name then
      self.potential = {}
      self.recent = {}
      self.mined_any = nil
      return
    end
  
    local unsorted = self.entity.surface.find_entities_filtered{
        type = "resource",
        area = self:get_mining_area(),
        name = target_name
    }

    util.highlight_bbox(self.entity.surface, self:get_mining_area())
  
    self.potential = self:sort_by_distance(unsorted)
    self.recent = {}
    self.mined_any = nil
end


---Get an entity to mine from the already stored list of targeted resources
---@return LuaEntity?
function camp:find_entity_to_mine()
    local targeted_resources = script_data.targeted_resources[self.surface_index]
  
    local recent = self.recent
  
    -- Magic - something to do with already started resources I think
    for entity_index, bool in pairs (recent) do
        local target_data = targeted_resources[entity_index]
        if target_data.entity.valid then
            target_data.camps[self.unit_number] = true
            if target_data.mining < target_data.max_mining then
                target_data.mining = target_data.mining + 1
                if target_data.mining >= target_data.max_mining then
                    recent[entity_index] = nil
                end
                return target_data.entity
            end
        end
        recent[entity_index] = nil
    end
  
    -- No resource left
    local entities = self.potential
    if not entities[1] then return end
  
    local size = #entities
    -- Find the closest valid resource (I think)
    while true do
      local entity_index = entities[size]
      if not entity_index then break end
  
      local target_data = targeted_resources[entity_index]
      if target_data.entity.valid then
        target_data.camps[self.unit_number] = true
        
        -- More magic
        if target_data.mining < target_data.max_mining then
          target_data.mining = target_data.mining + 1
          if target_data.mining >= target_data.max_mining then
            entities[size] = nil
          end
          return target_data.entity
        end
      end

      entities[size] = nil
      size = size - 1
    end
end

---Remove a worker and add their mining target back to the list and possibly remove the worker from the camp's inventory
---@param worker CampWorkerData The worker to remove
---@param remove_item boolean? Remove the worker from the camp's inventory
function camp:remove_worker(worker, remove_item)
    if remove_item then
        self:get_worker_inventory().remove{name = camp_defines.camps[self.entity_name].worker_name, count = 1}
    end
  
    local mining_target = worker.mining_target
    if mining_target and mining_target.valid then
        self:add_mining_target(mining_target)
    end
  
    worker.mining_target = nil
  
    self.workers[worker.unit_number] = nil
end

---TODO comments
---@param resource_entity LuaEntity
---@return integer
function camp:get_mining_count(resource_entity)
    if not self.target_carry_count then error("target_carry_count not set") end

    return math.min(self.target_carry_count, resource_entity.amount) --[[@as integer]]
end

---Order a worker to mine a certain entity
---@param worker CampWorkerData
---@param resource_entity LuaEntity
function camp:order_worker(worker, resource_entity)
    if not self.mined_any then
      self.mined_any = true
    end
  
    local mining_count = self:get_mining_count(resource_entity)
  
    worker.entity.speed = self:get_worker_speed()
    worker:mine_entity(resource_entity, mining_count)
end

---Set a worker's order or delete the worker cleanly if no request is outstanding
---@param worker_data CampWorkerData
function camp:handle_order_request(worker_data)
    if not (worker_data.mining_target and worker_data.mining_target.valid) then
        self:return_worker(worker_data)
        return
    end
  
    local should_spawn_count = (self:get_should_spawn_worker_count(true))
    if should_spawn_count <= 0 then
        self:return_worker(worker_data)
        return
    end

    self:order_worker(worker_data, worker_data.mining_target)
end


---Get the camp's output inventory
---@return LuaInventory
function camp:get_output_inventory()
    local output = self.entity.get_output_inventory()
    if not output then error("No output inventory") end
    return output
end

---Get the camp's worker inventory (input)
---@return LuaInventory
function camp:get_worker_inventory()
    local input = self.entity.get_inventory(defines.inventory.assembling_machine_input)
    if not input then error("No input inventory") end
    return input
end

---Iterate over a camp's output inventory and return the highest count
---@return integer? count Highest count or nil if no recipe is selected
function camp:get_max_output_amount()
    local inventory = self:get_output_inventory()
    local amount = 0
    local recipe = self.entity.get_recipe()
    if not recipe then return end
    for k, product in pairs (recipe.products) do
        amount = math.max(amount, inventory.get_item_count(product.name))
    end
    return amount
end

---Event handler for path requests
---@param event EventData.on_script_path_request_finished
function camp:handle_path_request_finished(event)
    local entity = self.path_requests[event.id]
    if not (entity and entity.valid) then return end
  
    if not self.entity.valid then
        self:add_mining_target(entity, true)
        return
    end
  
    self.path_requests[event.id] = nil
  
    if event.try_again_later then
        self:say("Try again later")
        self:attempt_to_mine(entity)
        return
    end
  
    if not (event.path and self.entity.valid) then
        --we can't reach it, don't spawn any workers.
        self:say("Can't reach")
        self:add_mining_target(entity, true)
        return
    end
    local worker = self:spawn_worker()
    
    if not worker then
        self:say("Can't spawn")
         --For some reason, we can't spawn a worker
        self:add_mining_target(entity)
        return
    end
    self:say("Spawned")
    self:order_worker(worker, entity)
end

local direction_name =
{
  [0] = "north",
  [2] = "east",
  [4] = "south",
  [6] = "west"
}

---Event handler for when a worker deposits a resource
function camp:on_resource_given()
    self:say("Resource given")
    return
end

---Destroy a worker and clean up nicely
---@param worker CampWorkerData
function camp:return_worker(worker)
    self:remove_worker(worker)
    worker:clear_things()
    worker.entity.destroy()
end


---Decrement the "mining" count of the resource's target_data and add the resource's index all the camps targeting this resource to their recent map
---@param resource_entity LuaEntity
---@param ignore_self boolean? Don't at the resource to this camp's recent map
function camp:add_mining_target(resource_entity, ignore_self)
    local targeted_resources = script_data.targeted_resources[self.surface_index]
    local index = unique_index(resource_entity)
    local target_data = targeted_resources[index]
    target_data.mining = target_data.mining - 1
  
    if target_data.mining < 0 then
        error("HUHEKR?")
    end
  
    for camp_index, bool in pairs(target_data.camps) do
        if not ignore_self or camp_index ~= self.unit_number then
            local camp_data = get_camp(camp_index)
            if camp_data then
            if not camp_data.recent then
                camp_data.recent = {}
            end
            camp_data.recent[index] = true
            end
        end
    end
end

---Remove this camp from the script_data.camps array
function camp:remove_from_list()
    local unit_number = self.unit_number
    script_data.camps[unit_number] = nil
end


---Clear this camps from the script_data.path_requests and reset the camps path_requests
function camp:clear_path_requests()
    local global_requests = script_data.path_requests
    for k, entity in pairs (self.path_requests) do
        self:add_mining_target(entity, true)
        global_requests[k] = nil
    end
    self.path_requests = {}
end


---Handler for all deletion events
function camp:handle_camp_deletion()
    self:cancel_all_orders()
    self.workers = nil
end

---Get the number of active workers
---@return integer
function camp:get_active_worker_count()
    return table_size(self.workers)
end

---TODO
local process_request_queue = function()
    if next(script_data.path_requests) then return end
    for camp_unit_number, resources in pairs (script_data.request_queue) do
        local camp_data = get_camp(camp_unit_number)
        if camp_data then
            local entity_index, resource_entity = next(resources)
            if resource_entity then
                if resource_entity.valid then
                    camp_data:request_path(resource_entity)
                end
                resources[entity_index] = nil
            end
        else
            script_data.request_queue[camp_unit_number] = nil
        end
    end
end

---On tick event handler
---@param event EventData.on_tick
local on_tick = function(event)
    local do_update = event.tick % 60 == 0
    if do_update then
      for unit_number, camp_data in pairs (script_data.camps) do
        if not (camp_data.entity.valid) then
          camp_data:handle_camp_deletion()
          script_data[unit_number] = nil
        else
          camp_data:update()
        end
      end
    end

    if event.tick % path_queue_rate == 0 then
      process_request_queue()
    end
end

---Get the bounding box and collision mask of a worker prototype
---@param prototype_name string
---@return BoundingBox
---@return CollisionMask
local get_box_and_mask = function(prototype_name)
    if not (box and mask) then
        local prototype = game.entity_prototypes[prototype_name]
        box = prototype.collision_box
        mask = prototype.collision_mask
    end
    return box, mask
end

---Add a request an entity to the camp's request queue
---@param resource_entity LuaEntity
function camp:attempt_to_mine(resource_entity)
  local request_queue = script_data.request_queue[self.unit_number]
  if not request_queue then
    request_queue = {}
    script_data.request_queue[self.unit_number] = request_queue
  end

  table.insert(request_queue, resource_entity)
end

---@type PathfinderFlags
local flags = {cache = false, low_priority = false}

---Will make a path request, and if it passes, send a worker to go mine it.
---@param resource_entity LuaEntity
function camp:request_path(resource_entity)
    local box, mask = get_box_and_mask(camp_defines.camps[self.entity_name].worker_name)
    util.highlight_position(self.entity.surface, resource_entity.position, {r=1, g=0, b=0, a=1})
    util.highlight_position(self.entity.surface, self.entity.position, {r=0, g=1, b=0, a=1})
    local path_request_id = self.entity.surface.request_path{
        bounding_box = box,
        collision_mask = mask,
        start = self.entity.position,
        goal = resource_entity.position,
        force = self.entity.force,
        radius = resource_entity.get_radius() + 0.5,
        can_open_gates = true,
        pathfind_flags = flags
    }
  
    script_data.path_requests[path_request_id] = self
    self.path_requests[path_request_id] = resource_entity
end

---Event handler for request path finished
---@param event EventData.on_script_path_request_finished
local on_script_path_request_finished = function(event)
    local camp_data = script_data.path_requests[event.id]
    if not camp_data then return end
    
    script_data.path_requests[event.id] = nil
    camp_data:handle_path_request_finished(event)
end

---Event handler for all events that get raised when the camp gets removed
---@param event EventData.on_player_mined_entity|EventData.on_robot_mined_entity|EventData.on_entity_died|EventData.script_raised_destroy
local on_entity_removed = function(event)
    local unit_number = event.unit_number --[[@as integer?]]
    if not unit_number then
      local entity = event.entity
      if not (entity and entity.valid) then
        return
      end
      unit_number = entity.unit_number
    end
  
    if not unit_number then return end
  
    local camp_data = script_data.camps[unit_number]
    if not camp_data then return end
    
    camp_data:handle_camp_deletion()
end

---Check if target recipe has changed
function camp:check_for_rescan()
    if self.target_resource_name == self:get_target_resource_name() then
        return
    end
    self:target_name_changed()
end

---Cancel all orders on all camps
local cancel_all_camps = function()
    for unit_number, camp_data in pairs (script_data.camps) do
        camp_data:cancel_all_orders()
    end
end

---Find potential targets for all camps
local rescan_all_camps = function()
    for unit_number, camp_data in pairs (script_data.camps) do
        camp_data:find_potential_targets()
    end
end

--- Cancel all camps and then rescan
local reset_all_camps = function()
    cancel_all_camps()
    rescan_all_camps()
end

---Cancel all orders on all camps then clear the script data's targeted_resources
local clear_targeted_resources = function()
    for unit_number, camp_data in pairs (script_data.camps) do
        camp_data:cancel_all_orders()
    end
    for k, surface in pairs (script_data.targeted_resources) do
        script_data.targeted_resources[k] = {}
    end
end

local lib = {}

lib.events =
{
    [defines.events.on_built_entity] = on_built_entity,
    [defines.events.on_robot_built_entity] = on_built_entity,
    [defines.events.script_raised_revive] = on_built_entity,
    [defines.events.script_raised_built] = on_built_entity,

    [defines.events.on_script_path_request_finished] = on_script_path_request_finished,

    [defines.events.on_player_mined_entity] = on_entity_removed,
    [defines.events.on_robot_mined_entity] = on_entity_removed,

    [defines.events.on_entity_died] = on_entity_removed,
    [defines.events.script_raised_destroy] = on_entity_removed,

    [defines.events.on_tick] = on_tick
}


lib.on_init = function()
    global.camps = global.camps or script_data
end

lib.on_load = function()
    script_data = global.camps or script_data
    for unit_number, camp_data in pairs (script_data.camps) do
        setmetatable(camp_data, camp_metatable)
    end
    for path_request_id, camp_data in pairs (script_data.path_requests) do
        setmetatable(camp_data, camp_metatable)
    end
end

lib.on_configuration_changed = function()
    if not global.camps then 
        global.camps = script_data
    end
    if not script_data.big_migration then
        script_data.big_migration = true
        script_data.targeted_resources = {}
        script_data.path_requests = {}
        for k, surface in pairs (game.surfaces) do
            script_data.targeted_resources[surface.index] = {}
        end
        
        for unit_number, camp_data in pairs (script_data.camps) do
            camp_data.path_requests = {}
        end
        script_data.request_queue = {}
    end
  
    for unit_number, camp_data in pairs (script_data.camps) do
        --Idk, things can happen, let the camps rescan if they want.
        if camp_data.entity.valid then
            camp_data:check_for_rescan()
        else
            camp_data:handle_camp_deletion()
            camp_data[unit_number] = nil
        end
    end
  
    -- if not script_data.migrate_drones then
    --   script_data.migrate_drones = true
    --     for unit_number, camp in pairs (script_data.camps) do
    --         for worker_unit_number, worker in pairs (camp.workers) do
    --             camp.workers[worker_unit_number] = true
    --         end
    --     end
    -- end
end

lib.add_commands = function()
    commands.add_command("ba-camps-rescan", "Forces all camps to cancel all orders and refresh their target list", reset_all_camps)
end

return lib