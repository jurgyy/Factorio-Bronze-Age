-- Largely copied from Mining Drones by Klonan
local shared_util = require("shared/shared-util")


---@type CampDefines
local camps_data = require("__bronze-age__/shared/camp-defines")

---@class CampWorkerScriptData
---@field workers table<integer, CampWorkerData> The scripts workers index by their unit number
---@field big_migration boolean Big migration
local script_data =
{
  workers = {},
  big_migration = true
}

---@enum CampWorkerStates
local states =
{
  mining_entity = 1,
  return_to_camp = 2
}

---@type PathfinderFlags
local worker_path_flags = {prefer_straight_paths = false, use_cache = false}

---@class CampWorkerData
---@field entity LuaEntity The worker entity
---@field unit_number integer The worker entity's unit number
---@field force_index integer The worker entity's force index
---@field camp integer The unit number of the camp entity that spawned this worker
---@field inventory LuaInventory The worker's inventory
---@field mining_target LuaEntity? The targeting entity (not proxy, I think)
---@field state CampWorkerStates? Current state of the worker
---@field fail_count integer? Number of times a worker failed its command
---@field mining_count integer? IDK TODO
local camp_worker = {}

camp_worker.metatable = {__index = camp_worker}

---Will be overwritten when worker-camp gets loaded
---@param unit_number integer
---@return CampData?
camp_worker.get_mining_camp = function(unit_number)
    error("Try to use get_camp before set up?")
end

---Add a worker to the script data
---@param worker CampWorkerData
local add_worker = function(worker)
    script_data.workers[worker.unit_number] = worker
end

---Remove a worker from the script data
---@param worker CampWorkerData
local remove_worker = function(worker)
    script_data.workers[worker.unit_number] = nil
end
  
---Get a worker from the script data
---@param unit_number integer
---@return CampWorkerData?
local get_worker = function(unit_number)
    local worker = script_data.workers[unit_number]
  
    if not worker then
        return
    end
  
    if not worker.entity.valid then
        worker:clear_things()
        return
    end
  
    return worker
end

---Get worker mining speed (a constant)
---@return number
local get_worker_mining_speed = function()
    return 0.5
end

---@type table<string, number> Mining time cache
local mining_times = {}

---Get mining time of a given resource entity
---@param resource_entity LuaEntity
---@return number
local get_mining_time = function(resource_entity)
  local name = resource_entity.name
  local time = mining_times[name]
  if time then return time end

  time = resource_entity.prototype.mineable_properties.mining_time
  mining_times[name] = time
  return time
end

---@type table<string, string> Mining proxy name cache: t<resource_name, proxy_name>
local proxy_names_cache = {}
---Get the name of the mining proxy of a given resource entity
---@param resource_entity LuaEntity
---@return string
local get_proxy_name = function(resource_entity)
    local entity_name = resource_entity.name
    local proxy_name = proxy_names_cache[entity_name]
    if proxy_name then
        return proxy_name
    end
    
    proxy_name = shared_util.get_proxy_name(resource_entity.prototype --[[@as CampSupportedEntityPrototypes]])
    if not game.entity_prototypes[proxy_name] then
        error("Proxy not registered")
    end

    proxy_names_cache[entity_name] = proxy_name

    return proxy_name
end

---Get mining speed. Currently constant might introduce bonuses later
---@return number
function camp_worker:get_mining_speed()
    return 0.5
end

function camp_worker:make_attack_proxy()
    --Health is set so it will take just enough mining_damage at exactly the right time
    local entity = self.mining_target
    if not entity then error("No mining target") end

    local count = self.mining_count
    local mining_time = get_mining_time(entity) * count
    local mining_interval = camps_data.workers[self.entity.name].mining_interval
    local mining_damage = camps_data.workers[self.entity.name].mining_damage
  
    local number_of_ticks = (mining_time / self:get_mining_speed()) * 60
    local number_of_hits = math.ceil(number_of_ticks / mining_interval)
    local position = entity.position
    local radius = entity.get_radius() * 0.707
    if radius > 0.5 then
      local r2 = math.random() * (radius ^ 2)
      local angle = math.random() * math.pi * 2
      position.x = position.x + (r2^0.5) * math.cos(angle)
      position.y = position.y + (r2^0.5) * math.sin(angle)
    end
    local proxy = entity.surface.create_entity{name = get_proxy_name(entity), position = position, force = "neutral"}
    proxy.health = number_of_hits * mining_damage
    proxy.active = false
  
    self.attack_proxy = proxy
end

---Initialize a new worker
---@param entity LuaEntity The worker entity
---@param camp CampData The camp data that spawned this worker
---@return CampWorkerData
camp_worker.new = function(entity, camp)
    ---@type CampWorkerData
    local worker = {
        entity = entity,
        unit_number = entity.unit_number,
        force_index = entity.force.index,
        camp = camp.entity.unit_number,
        inventory = game.create_inventory(100)
    }
    entity.ai_settings.path_resolution_modifier = 0
    setmetatable(worker, camp_worker.metatable)

    add_worker(worker)
    return worker
end

---Get this worker's camp
function camp_worker:get_camp()
    if not self.camp then return end
    return camp_worker.get_mining_camp(self.camp)
end

function camp_worker:process_mining()
    local target = self.mining_target
    if not (target and target.valid) then
        --cancel command or something.
        return self:return_to_camp()
    end
  
    local camp_data = self:get_camp()
    if not camp_data then
        self:cancel_command()
        return
    end
  
  
    -- local pollute = self.entity.surface.pollute
    -- local pollution_flow = game.pollution_statistics.on_flow
  
    -- pollute(target.position, pollution_per_mine)
    -- pollution_flow(default_bot_name, pollution_per_mine)
  
    --if target.type ~= "resource" then error("HUEHRUEH") end
  
    local mine_opts = {inventory = self.inventory}
    local mine = target.mine
    for k = 1, self.mining_count do
        if target.valid then
            mine(mine_opts)
        else
            self:clear_mining_target()
            break
        end
    end
    self.mining_count = nil
    self:return_to_camp()
end

---Ask the camp to set the worker's command or delete the worker cleanly if no request is outstanding 
function camp_worker:request_order()
    self:get_camp():handle_order_request(self)
end

local distance = util.distance
---Get The distance between the worker and a given position
---@param position MapPosition
---@return number
function camp_worker:distance(position)
  return distance(self.entity.position, position)
end

---Handler for when a worker reaches a camp or deletes the worker if the camp is not valid or they are too far away
function camp_worker:process_return_to_camp()
    local camp = self:get_camp()
    if not (camp and camp.entity.valid) then
        self:cancel_command()
        return
    end
  
    -- TODO grab the camp's radius to calculate the correct distance
    if self:distance(camp.entity.position) > 5 then
        self:return_to_camp()
        return
    end
  
    local target_inventory = camp:get_output_inventory()
    local productivity_bonus = 1 --+ mining_technologies.get_productivity_bonus(self.force_index)
    -- local chance = productivity_bonus % 1
    -- productivity_bonus = productivity_bonus - chance
  
    -- if chance > math.random() then
    --     productivity_bonus = productivity_bonus + 1
    -- end
  
  
    local item_flow = self.entity.force.item_production_statistics.on_flow
    for name, count in pairs (self.inventory.get_contents()) do
        local real_count = math.ceil(count * productivity_bonus)
        target_inventory.insert({name = name, count = real_count})
        item_flow(name, real_count)
    end
    camp:on_resource_given()
  
    self.inventory.clear()
  
    self:request_order()
end


function camp_worker:process_failed_command()
    self.fail_count = (self.fail_count or 0) + 1
  
    if self.fail_count == 2 then self.entity.ai_settings.path_resolution_modifier = 1 end
    if self.fail_count == 4 then self.entity.ai_settings.path_resolution_modifier = 2 end
  
    if self.state == states.mining_entity then
      self:clear_attack_proxy()
  
      if self.mining_target.valid and self.fail_count <= 5 then
        return self:mine_entity(self.mining_target, self.mining_count)
      end
  
      --self:say("I can't mine that entity!")
      self:clear_mining_target()
      self:return_to_camp()
      return
    end
  
    if self.state == states.return_to_camp then
      if self.fail_count <= 5 then
        return self:wait(math.random(25, 45))
      end
      --self:say("I can't return to my depot!")
      self:cancel_command()
      return
    end
end

---Wait a number of ticks
---@param ticks integer
function camp_worker:wait(ticks)
    self.entity.set_command
    {
      type = defines.command.wander,
      ticks_to_wait = ticks,
      distraction = defines.distraction.none
    }
end

---TODO when is the worker distracted?
function camp_worker:process_distracted_command()
    if self.state == states.mining_entity then
        -- We were in the middle of attacking the proxy, go mine it.
        self:attack_mining_proxy()
        return
    end

    if self.state == states.return_to_camp then
        -- We were walking home, lets walk home again.
        self:return_to_camp()
        return
    end
end

---Update the worker after completing a command
---@param event EventData.on_ai_command_completed
function camp_worker:update(event)
    if not self.entity.valid then return end

    if event.result ~= defines.behavior_result.success then
        self:say("Command failed")
        self:process_failed_command()
        return
    end

    if event.was_distracted then
        self:say("Was distracted")
        self:process_distracted_command()
        return
    end

    if self.state == states.mining_entity then
        self:say("Mining completed")
        self:process_mining()
        return
    end

    if self.state == states.return_to_camp then
        self:say("Returning completed")
        self:process_return_to_camp()
        return
    end
end

---Spawn flying-text above the worker to say something
---@param text string
function camp_worker:say(text)
    self.entity.surface.create_entity{name = "flying-text", position = self.entity.position, text = text}
end

---Move to the attack proxy and start attacking it
function camp_worker:attack_mining_proxy()
    local camp_data = self:get_camp()
  
    if not (camp_data and camp_data.entity.valid) then
        self:cancel_command()
        return
    end
  
    local attack_proxy = self.attack_proxy
    if not (attack_proxy and attack_proxy.valid) then
        --dunno
        self:return_to_camp()
        return
    end
  
    local commands =
    {
    --   {
    --     type = defines.command.go_to_location,
    --     destination_entity = depot:get_corpse(),
    --     radius = 0.25,
    --     distraction = defines.distraction.none,
    --     pathfind_flags = drone_path_flags
    --   },
      {
        type = defines.command.go_to_location,
        destination_entity = attack_proxy,
        distraction = defines.distraction.none,
        pathfind_flags = worker_path_flags
      },
      {
        type = defines.command.attack,
        target = attack_proxy,
        distraction = defines.distraction.none
      }
    }

    self.entity.set_command
    {
      type = defines.command.compound,
      structure_type = defines.compound_command.return_last,
      distraction = defines.distraction.none,
      commands = commands
    }

end

---Make an attack proxy, move to it and start attacking it
---@param entity LuaEntity The resource entity (not proxy)
---@param count integer IDK TODO
function camp_worker:mine_entity(entity, count)
    self.mining_count = count or 1
    self.mining_target = entity
    self.state = states.mining_entity

    self:make_attack_proxy()
    self:attack_mining_proxy()
end

---Clear mining target, attack proxy and camp and lastly the worker itself from the script data (does not remove the entity)
function camp_worker:clear_things()
    self:clear_mining_target()
    self:clear_attack_proxy()
    self:clear_camp()
    remove_worker(self)
end

---Clear things then remove the worker
function camp_worker:cancel_command()
    self:clear_things()
    self.entity.force = "neutral"
    self.entity.die()
end


---Clear the attack proxy, then walk to the camp
function camp_worker:return_to_camp()
    self.state = states.return_to_camp
    self:clear_attack_proxy()
  
    local camp_data = self:get_camp()
  
    if not (camp_data and camp_data.entity.valid) then
        self:cancel_command()
        return
    end

    local commands =
    {
    --   {
    --     type = defines.command.go_to_location,
    --     destination_entity = depot:get_corpse(),
    --     radius = 0.25,
    --     distraction = defines.distraction.none,
    --     pathfind_flags = drone_path_flags
    --   },
        {
            type = defines.command.go_to_location,
            destination_entity = camp_data.entity, --depot:get_spawn_corpse(),
            radius = 1.5,
            distraction = defines.distraction.none,
            pathfind_flags = worker_path_flags
        }
    }

    self.entity.set_command
    {
        type = defines.command.compound,
        structure_type = defines.compound_command.return_last,
        distraction = defines.distraction.none,
        commands = commands
    }
end

---Set the worker's command to simply go to a given position
---@param position MapPosition Position
---@param radius number? How close the worker needs to reach. Defaults to 1
function camp_worker:go_to_position(position, radius)
    self.entity.set_command
    {
        type = defines.command.go_to_location,
        destination = position,
        radius = radius or 1,
        distraction = defines.distraction.none,
        pathfind_flags = worker_path_flags,
    }
end

---Set the worker's command to go to an entity
---@param entity LuaEntity
---@param radius number? How close to the entity. Defaults to 1
function camp_worker:go_to_entity(entity, radius)
    self.entity.set_command
    {
        type = defines.command.go_to_location,
        destination_entity = entity,
        radius = radius or 1,
        distraction = defines.distraction.none,
        pathfind_flags = worker_path_flags
    }
end


--- Clear the worker's attack proxy and destroy it
function camp_worker:clear_attack_proxy()
    if self.attack_proxy and self.attack_proxy.valid then
         self.attack_proxy.destroy()
    end
    self.attack_proxy = nil
end

---Add the target back to the camp's list of targets and set the worker's target to nil
function camp_worker:clear_mining_target()
    if self.mining_target and self.mining_target.valid then
        local camp = self:get_camp()
        if camp then
            camp:add_mining_target(self.mining_target)
        end
    end
    self.mining_target = nil
end

---Remove themselve from the camp's workers table and remove the camp from the worker's data
function camp_worker:clear_camp()
    if not self.camp then return end
    self:get_camp().workers[self.unit_number] = nil
    self.camp = nil
end

---Handler for when a worker gets deleted. Removes the worker from the camp and clears all worker things
function camp_worker:handle_worker_deletion()
    if not self.entity.valid then error("Hi, i am not handled.") end

    if self:get_camp() then
      self:get_camp():remove_worker(self, true)
    end

    self:clear_things()
end

---Event handler for command completed
---@param event EventData.on_ai_command_completed
local on_ai_command_completed = function(event)
    local worker = get_worker(event.unit_number)
    if not worker then return end
    worker:update(event)
end

---Event handler for all events that might remove a worker
---@param event EventData.on_player_mined_entity|EventData.on_robot_mined_entity|EventData.on_entity_died|EventData.script_raised_destroy
local on_entity_removed = function(event)
    local entity = event.entity
    if not (entity and entity.valid) then return end

    local unit_number = entity.unit_number
    if not unit_number then return end

    local worker = get_worker(unit_number)
    if not worker then return end

    -- if event.force and event.force.valid then
    --   event.force.kill_count_statistics.on_flow(default_bot_name, 1)
    -- end

    -- entity.force.kill_count_statistics.on_flow(default_bot_name, -1)

    worker:handle_worker_deletion()
end

---IDK TODO
local validate_proxy_orders = function()
    --local count = 0
    for unit_number, worker_data in pairs (script_data.workers) do
        if worker_data.entity.valid then
            if worker_data.state == states.mining_entity then
            if not worker_data.attack_proxy.valid then
                worker_data:return_to_camp()
                ---count = count + 1
            end
        end
        else
            worker_data:clear_things()
        end
    end
end

---Event handler that cancels the group addition, then destroys the group and command the worker to resume work
---@param event EventData.on_unit_added_to_group
local on_unit_added_to_group = function(event)
    local entity = event.unit
    if not (entity and entity.valid) then return end

    local worker = get_worker(entity.unit_number)
    if not worker then return end

    local group = event.group
    if not (group and group.valid) then return end

    group.destroy()

    worker:process_distracted_command()
end

camp_worker.events =
{
    [defines.events.on_player_mined_entity] = on_entity_removed,
    [defines.events.on_robot_mined_entity] = on_entity_removed,

    [defines.events.on_entity_died] = on_entity_removed,
    [defines.events.script_raised_destroy] = on_entity_removed,

    [defines.events.on_ai_command_completed] = on_ai_command_completed,

    [defines.events.on_unit_added_to_group] = on_unit_added_to_group,
}

camp_worker.on_load = function()
    script_data = global.camp_workers or script_data
    for unit_number, worker_data in pairs (script_data.workers) do
      setmetatable(worker_data, camp_worker.metatable)
    end
end

camp_worker.on_init = function()
    global.camp_workers = global.camp_workers or script_data
    game.map_settings.path_finder.use_path_cache = false
end

camp_worker.on_configuration_changed = function()
    if not global.camp_workers then
        global.camp_workers = script_data
    end
    if not script_data.big_migration then
        script_data.big_migration = true
        for unit_number, worker_data in pairs (script_data.workers) do
            script_data.workers[unit_number] = nil
            if worker_data.entity.valid then
                worker_data.entity.destroy()
            end
            if worker_data.attack_proxy and worker_data.attack_proxy.valid then
                worker_data.attack_proxy.destroy()
            end
        end
        script_data.workers = {}
    end

    validate_proxy_orders()
end

camp_worker.get_worker = get_worker

camp_worker.get_worker_count = function()
  return table_size(script_data.workers)
end

return camp_worker
