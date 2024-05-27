local ba_construction = require("construction")
local ba_commands = require("commands")

local util = require("ba-util")

local entity_name = "ba-worker"
local script_data = {
    n_workers = 0,
    max_workers = 2,
    workers = {}
}
local worker = {}

--- @class WorkerNextStepArgs
--- @field unit_data table|nil Optional. The data for the unit.
--- @field unit_number integer|nil Optional. The unit number to look up the data.

--- @class UnitData
--- @field entity LuaEntity Worker entity unit
--- @field force_index integer Worker force index
--- @field inventory LuaInventory The worker's inventory
--- @field step integer Step index of the worker's commands
--- @field command Command.defines_command_compound Compound command of all the worker's steps

--- Processes the next step for a worker.
--- @param args WorkerNextStepArgs The arguments table containing either `unit_data` or `unit_number`.
worker.next_step = function(args)
    --if true then return end
    local unit_data = args.unit_data or script_data.workers[args.unit_number]
    if not unit_data then
        util.print("Cannot find worker " .. args.unit_number)
        return
    end

    if not unit_data.entity.valid then
        util.print("Cannot execute step: Entity not valid")
        return
    end

    unit_data.step = unit_data.step + 1

    if unit_data.step > #unit_data.command.commands then
        worker.finalize_command(unit_data)
        return
    end
    worker.execute_step(unit_data)
end

worker.execute_step = function(unit_data)
    local command = unit_data.command.commands[unit_data.step]

    if command.type == defines.command.stop then
        ---@cast command StopCommandWithSubtype
        if command.subtype == "pickup" then
            ---@cast command PickupCommand
            local chests = unit_data.entity.surface.find_entities_filtered{
                name = "wooden-chest",
                position = unit_data.entity.position,
                radius = 1.5
            }
            
            if not chests then
                util.print("Chest not found")
                worker.finalize_command(unit_data)
                return
            end
            local inventory = chests[1].get_output_inventory()
            if inventory == nil then
                util.print("No inventory")
                worker.finalize_command(unit_data)
                return
            end
            local items = {name = command.item, count=command.amount}
            inventory.remove(items)

            -- todo stickers gebruiken?
            local e = unit_data.entity.surface.create_entity{
                name = "ba-pickup-text",
                position = unit_data.entity.position,
                text = command.amount .. "x [item=" .. command.item .. "]",
                speed = 0.5,
                time_to_live = 20
            }
            unit_data.inventory.insert(items)

        elseif command.subtype == "dropoff" then
            ---@cast command DropoffCommand
            local chests = unit_data.entity.surface.find_entities_filtered{
                name = "wooden-chest",
                position = unit_data.entity.position,
                radius = 1.5
            }

            if not chests or #chests == 0 then
                util.print("Chest not found")
                --unit_data.entity.surface.spill_item_stack(unit_data.entity.position, {name=command.item, count=command.amount}, false, "neutral", true)
                worker.finalize_command(unit_data)
                return
            end

            local chest
            for _, v in ipairs(chests) do
                if v.valid then
                    chest = v
                end
            end
            if not chest then
                util.print("No valid chest found")
                --unit_data.entity.surface.spill_item_stack(unit_data.entity.position, {name=command.item, count=command.amount}, false, "neutral", true)
                worker.finalize_command(unit_data)
                return
            end

            chest.insert({name = command.item, count=command.amount})

            local e = unit_data.entity.surface.create_entity{
                name = "ba-dropoff-text",
                position = unit_data.entity.position,
                text = command.amount .. "x [item=" .. command.item .. "]",
                speed = 10,
                time_to_live = 20
            }
        elseif command.subtype == "dropoff-chest" then
            ---@cast command DropoffChestCommand
            local chest = command.chest --[[@as LuaEntity]]
            if not chest.valid then
                util.print("Chest not valid anymore")
                worker.finalize_command(unit_data)
                return
            end

            local chest_inventory = chest.get_output_inventory()
            if not chest_inventory or not chest_inventory.can_insert(unit_data.inventory[1]) then
                util.print("Cannot insert items in chest")
                worker.finalize_command(unit_data)
                return
            end
            local inserted = chest_inventory.insert(unit_data.inventory[1])
            unit_data.inventory.remove{name = unit_data.inventory[1].name, count = inserted }

            worker.finalize_command(unit_data)
            return
        elseif command.subtype == "dropoff-build" then
            ---@cast command DropoffBuildCommand
            local delivered = ba_construction.deliver_item(
                command.ghost_id,
                unit_data.entity.surface,
                command.ghost_pos,
                {name=command.item, count=command.amount}
            )

            if not delivered then
                util.print("not delivered")
                --unit_data.entity.surface.spill_item_stack(unit_data.entity.position, {name=command.item, count=command.amount}, false, "neutral", true)
                --return_items(unit_data)
                local return_chest = util.find_chest_exponential(unit_data.entity.surface, unit_data.entity.position, true, unit_data.inventory[1], nil)
                if return_chest then
                    local new_command = {
                        type = defines.command.compound,
                        structure_type = defines.compound_command.logical_and,
                        distraction = defines.distraction.none,
                        commands = {
                            ba_commands.wait_command(30),
                            ba_commands.go_to_command(return_chest.position),
                            ba_commands.dropoff_chest_command(return_chest, unit_data.inventory[1]),
                        }
                    } --[[@as Command]]
                    unit_data.command = new_command
                    unit_data.step = 1
                    command = unit_data.command.commands[unit_data.step]
                else
                    worker.finalize_command(unit_data)
                    return
                end
            else
                unit_data.entity.surface.create_entity{
                    name = "ba-dropoff-text",
                    position = unit_data.entity.position,
                    text = command.amount .. "x [item=" .. command.item .. "]",
                    speed = 10,
                    time_to_live = 20
                }
                unit_data.inventory.destroy()
                worker.finalize_command(unit_data)
                return
            end
        end
    end

    unit_data.entity.set_command(command)
end

worker.cancel_commands = function()
    error("not implemented")
end

worker.finalize_command = function(unit_data)
    script_data.n_workers = script_data.n_workers - 1
    
    worker_inventory = script_data.workers[unit_data.unit_number].inventory --[[@as LuaInventory|nil]]
    if worker_inventory and worker_inventory.valid then
        for item, amount in pairs(worker_inventory.get_contents()) do
            unit_data.entity.surface.spill_item_stack(unit_data.entity.position, {name=item, count=amount}, false, "neutral", true)
        end
        worker_inventory.destroy()
    end
    script_data.workers[unit_data.unit_number] = nil
    
    if unit_data.entity and unit_data.entity.valid then
        unit_data.entity.destroy()
    else
        util.print("Entity not set or not valid")
    end

    util.print("Unit " .. unit_data.unit_number .. " completed commands")
end

worker.can_spawn = function()
    if script_data.n_workers >= script_data.max_workers then
        util.print("Maximum number of workers reached")
        return false
    end
    return true
end

---Create the unit data to transform a Entity into a worker.
---@param entity LuaEntity The to-be worker entity
---@return UnitData
worker.new = function(entity)
    local unit_data =
    {
      entity = entity,
      unit_number = entity.unit_number,
      force_index = entity.force.index,
      inventory = game.create_inventory(1),
      step = 0,
      command = nil
    }
    entity.ai_settings.path_resolution_modifier = 0
  
    script_data.n_workers = script_data.n_workers + 1
    script_data.workers[entity.unit_number] = unit_data
    return unit_data
end

---Spawn a new worker entity without checking if the max number of workers has been exceeded.
---@param surface LuaSurface
---@param position MapPosition
---@param force string|integer|LuaForce
---@return UnitData|nil
worker.spawn_unlimited = function(surface, position, force)
    if not surface.can_place_entity {
        name = entity_name,
        position = position,
        force = force
    } then
        util.print("Can't spawn worker at " .. position.x .. ", " .. position.y)
        return
    end

    local entity = surface.create_entity{
        name = "ba-worker",
        position = position,
        force = force
    }

    if not entity or not entity.valid then
        return
    end

    return worker.new(entity)
end

---comment
---@param event EventData.on_ai_command_completed
local function on_ai_command_completed(event)
    if event.result == defines.behavior_result.success then
        util.print("Command completed: " .. event.unit_number)
        worker.next_step{unit_number = event.unit_number}
        return
    end

    util.print("Command not succeeded")
    worker.finalize_command(script_data.workers[event.unit_number])
end

worker.events = {
  [defines.events.on_ai_command_completed] = on_ai_command_completed,
}

worker.foo = function()
    global.worker = script_data
    script_data = global.worker
end

worker.on_load = function()
    script_data = global.worker or script_data
    -- for unit_number, drone in pairs (script_data.drones) do
    --     setmetatable(drone, mining_drone.metatable)
    -- end
end
  
worker.on_init = function()
    global.worker = global.worker or script_data
    --game.map_settings.path_finder.use_path_cache = false
end

return worker