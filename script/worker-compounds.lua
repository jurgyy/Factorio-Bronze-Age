local shared_util = require("shared/shared-util")
local get_entities_with_workers_defines = require("shared/entity-with-workers-defines")


---@type ScriptObjectWithWorkers
local object_with_workers = require("script/object-with-workers")

---@class WorkerCompoundsData : ScriptObjectWithWorkers
---@field eei LuaEntity
---@field pole LuaEntity
local worker_compounds = object_with_workers:new()
local metatable = {
    __index = worker_compounds
}

---@class WorkerCompoundsScriptData
---@field compounds table<integer, WorkerCompoundsData> Source entity unit number mapping to data table
local script_data = {
    compounds = {}
}

local function spawn_compound(source_entity, name)
    local compound = source_entity.surface.create_entity{
        name = name,
        --position = source_entity.position,
        position = {x = source_entity.position.x + 1, y = source_entity.position.y},
        force = source_entity.force
    }
    if not compound or not compound.valid then
        error(name .. " not valid")
    end
    return compound
end

local function spawn_compound2(source_entity, name)
    local compound = source_entity.surface.create_entity{
        name = name,
        position = {x = source_entity.position.x - 1, y = source_entity.position.y},
        force = source_entity.force
    }
    if not compound or not compound.valid then
        error(name .. " not valid")
    end
    return compound
end


---@param entity LuaEntity
---@return WorkerCompoundsData?
function worker_compounds:new(entity)
    local entity_define = get_entities_with_workers_defines()[entity.name]
    if not entity_define then return end
    game.print("New")

    local compounds_data = object_with_workers.new(self, entity, entity_define.max_workers, {
        eei = spawn_compound(entity, "compound-eei"),
        pole = spawn_compound2(entity, "electric-pole-compound")
    })

    setmetatable(compounds_data, metatable)
    --[[@cast compounds_data WorkerCompoundsData]]
    
    script_data.compounds[entity.unit_number] = compounds_data

    compounds_data.eei.power_production = 0

    return compounds_data
end

function worker_compounds:handle_entity_deletion()
    game.print("deletion")
    if self.eei and self.eei.valid then
        self.eei.destroy()
    end

    if self.pole and self.pole.valid then
        self.pole.destroy()
    end

    script_data.compounds[self.entity.unit_number] = nil
    self:handle_deletion()
end

function worker_compounds:on_workers_set()
    game.print("worker_compounds")
    local ratio = self.assigned_workers / self.max_workers
    self.eei.power_production = self.max_workers * ratio / 60 -- Unit is in joulticks therefore divide it by 60
end


---@param event EventData.on_built_entity|EventData.on_robot_built_entity|EventData.script_raised_revive|EventData.script_raised_built
local on_built_entity = function(event)
    local entity = event.entity or event.created_entity
    if not (entity and entity.valid) then return end
  
    worker_compounds:new(entity)
end


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
  
    local eei_data = script_data.compounds[unit_number]
    if not eei_data then return end
    
    eei_data:handle_entity_deletion()
end



local lib = {}

lib.events =
{
    [defines.events.on_built_entity] = on_built_entity,
    [defines.events.on_robot_built_entity] = on_built_entity,
    [defines.events.script_raised_revive] = on_built_entity,
    [defines.events.script_raised_built] = on_built_entity,

    [defines.events.on_player_mined_entity] = on_entity_removed,
    [defines.events.on_robot_mined_entity] = on_entity_removed,

    [defines.events.on_entity_died] = on_entity_removed,
    [defines.events.script_raised_destroy] = on_entity_removed,

    --[defines.events.on_tick] = on_tick
}


lib.on_init = function()
    global.worker_compounds = global.worker_compounds or script_data
end

lib.on_load = function()
    script_data = global.worker_compounds or script_data
    if script_data.compounds then
        for unit_number, worker_eei in pairs (script_data.compounds) do
            setmetatable(worker_eei, metatable)
        end
    end
end

lib.on_configuration_changed = function()
    if not global.worker_compounds then
        global.worker_compounds = script_data
    end
end

return lib