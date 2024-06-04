local pickup_duration = 20
local dropoff_duration = 20

local commands = {}

---@class StopCommandWithSubtype : Command.defines_command_stop
---@field subtype string Subtype of the command

---comments
---@param position MapPosition Position to go to
---@param radius number|nil Distance allowed from the position. Defaults to 1
---@return Command.defines_command_go_to_location go_to_command
function commands.go_to_command(position, radius)
    radius = radius or 1
    return {
        type = defines.command.go_to_location,
        destination = position,
        radius = radius,
        distraction = defines.distraction.none,
        pathfind_flags = {prefer_straight_paths = true, use_cache = true, allow_paths_through_own_entities = true}
    }
end

---comments
---@param entity LuaEntity Entity to go to
---@return Command.defines_command_go_to_location go_to_command
function commands.go_to_entity_command(entity)
    radius = radius or 1
    return {
        type = defines.command.go_to_location,
        destination_entity = entity,
        radius = 1,
        distraction = defines.distraction.none,
        pathfind_flags = {prefer_straight_paths = true, use_cache = true, allow_paths_through_own_entities = true}
    }
end

---comments
---@param ticks_to_wait integer
---@return Command.defines_command_stop
function commands.wait_command(ticks_to_wait)
    return {
        type = defines.command.stop,
        distraction = defines.distraction.none,
        ticks_to_wait = ticks_to_wait,
    }
end

---@class PickupCommand : StopCommandWithSubtype
---@field item string
---@field amount integer

---comments
---@param pickup_request any
---@return PickupCommand
function commands.pickup_command(pickup_request)
    return {
        type = defines.command.stop,
        subtype = "pickup",
        distraction = defines.distraction.none,
        ticks_to_wait = pickup_duration,
        item = pickup_request.item,
        amount = pickup_request.amount
    }
end

---@class DropoffChestCommand : StopCommandWithSubtype
---@field item_stack SimpleItemStack
---@field chest LuaEntity

---comments
---@param chest LuaEntity The chest to drop the item_stack in
---@return DropoffChestCommand
function commands.dropoff_chest_command(chest, item_stack)
    return {
        type = defines.command.stop,
        subtype = "dropoff-chest",
        distraction = defines.distraction.none,
        ticks_to_wait = dropoff_duration,
        item_stack = item_stack,
        chest = chest
    }
end


---@class PickupV2Command : StopCommandWithSubtype
---@field item string
---@field amount integer

---comments
---@param request BuildItemRequest|ItemDeliveryRequest
---@return PickupV2Command
function commands.pickup_v2_command(request)
    return {
        type = defines.command.stop,
        subtype = "pickup",
        distraction= defines.distraction.none,
        ticks_to_wait = pickup_duration,
        item = request.ingredient.name,
        amount = request.ingredient.amount
    }
end

---@class DropoffBuildCommand : StopCommandWithSubtype
---@field item string
---@field amount integer
---@field ghost_id integer
---@field ghost_pos MapPosition

---comments
---@param build_item_request BuildItemRequest
---@return DropoffBuildCommand
function commands.dropoff_build_command(build_item_request)
    return {
        type = defines.command.stop,
        subtype = "dropoff-build",
        distraction= defines.distraction.none,
        ticks_to_wait = dropoff_duration,
        item = build_item_request.ingredient.name,
        amount = build_item_request.ingredient.amount,
        ghost_id = build_item_request.ghost.unit_number,
        ghost_pos = build_item_request.ghost.position
    }
end

return commands