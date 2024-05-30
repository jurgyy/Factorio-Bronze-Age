local ba_construction = require("construction")
local ba_commands = require("commands")
local ba_requests = require("requests")

local util = require("ba-util")

local entity_name = "ba-worker"
local worker = {}

--- @class WorkerData
--- @field n_workers integer Current amount of workers active
--- @field max_workers integer Maximum number of workers active at any one time
--- @field workers table<integer, UnitData> Table of all workers' unit_data indexed by their unit_number

--- @class WorkerNextStepArgs
--- @field unit_data table|nil Optional. The data for the unit.
--- @field unit_number integer|nil Optional. The unit number to look up the data.

--- @class UnitData
--- @field entity LuaEntity Worker entity unit
--- @field force_index integer Worker force index
--- @field inventory LuaInventory The worker's inventory
--- @field step integer Step index of the worker's commands
--- @field command Command.defines_command_compound Compound command of all the worker's steps
--- @field request Request

--- Processes the next step for a worker.
--- @param args WorkerNextStepArgs The arguments table containing either `unit_data` or `unit_number`.
worker.next_step = function(args)
    --if true then return end
    local unit_data = args.unit_data or global.worker_data.workers[args.unit_number]
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

---Change the current command with a new command. Does not add the old command back to the request queue.
---@param unit_data UnitData
---@param new_command Command.defines_command_compound
local function change_command(unit_data, new_command)
    unit_data.command = new_command
    unit_data.step = 1
    command = unit_data.command.commands[unit_data.step]
    worker.execute_step(unit_data)
end

--- Change the command to return the items in the worker's inventory
---@param unit_data UnitData The worker's data.
---@return boolean Set Is true when a new command is set.
local function return_items(unit_data)
    if unit_data.inventory.is_empty() then
        return false
    end

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
        change_command(unit_data, new_command)
    else
        return false
    end
    return true
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
                local ghost = ba_construction.find_ghost(command.ghost_id, unit_data.entity.surface, command.ghost_pos)
                if ghost then
                    ba_requests.add_request(ba_requests.request_building_item(
                    ghost,
                    {
                        name = command.item,
                        count = command.amount
                    }))
                else
                    util.print("Unable to re-add the request")
                end

                success = return_items(unit_data)
                if not success then
                    worker.finalize_command(unit_data)
                    return
                end
            else
                unit_data.inventory.remove{name=command.item, count=command.amount}
                unit_data.entity.surface.create_entity{
                    name = "ba-dropoff-text",
                    position = unit_data.entity.position,
                    text = command.amount .. "x [item=" .. command.item .. "]",
                    speed = 10,
                    time_to_live = 20
                }
                
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
    worker_inventory = global.worker_data.workers[unit_data.unit_number].inventory --[[@as LuaInventory|nil]]
    if worker_inventory and worker_inventory.valid then
        if return_items(unit_data) then
            return
        else
            for item, amount in pairs(worker_inventory.get_contents()) do
                unit_data.entity.surface.spill_item_stack(unit_data.entity.position, {name=item, count=amount}, false, "neutral", true)
            end
        end
        worker_inventory.destroy()
    end
    global.worker_data.n_workers = global.worker_data.n_workers - 1
    global.worker_data.workers[unit_data.unit_number] = nil
    
    if unit_data.entity and unit_data.entity.valid then
        unit_data.entity.destroy()
    else
        util.print("Entity not set or not valid")
    end

    util.print("Unit " .. unit_data.unit_number .. " completed commands")
end

worker.can_spawn = function()
    if global.worker_data.n_workers >= global.worker_data.max_workers then
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
  
    global.worker_data.n_workers = global.worker_data.n_workers + 1
    global.worker_data.workers[entity.unit_number] = unit_data
    return unit_data
end

---Spawn a new worker entity without checking if the max number of workers has been exceeded.
---@param surface LuaSurface
---@param position MapPosition
---@param force string|integer|LuaForce
---@param request Request
---@return UnitData|nil
worker.spawn_unlimited = function(surface, position, force, request)
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

    local unit_data = worker.new(entity)
    unit_data.request = request
    return unit_data
end

---comment
---@param event EventData.on_ai_command_completed
worker.on_ai_command_completed = function(event)
    if event.result == defines.behavior_result.success then
        util.print("Command completed: " .. event.unit_number)
        worker.next_step{unit_number = event.unit_number}
        return
    end

    util.print("Command not succeeded")
    local unit_data = global.worker_data.workers[event.unit_number]
    if unit_data then
        if unit_data.request then
            unit_data.request.steps_completed = unit_data.step - 1
            ba_requests.add_request(unit_data.request)
        end
        worker.finalize_command(unit_data)
    else
        error("Unable to retrieve unit_data")
    end
end

return worker