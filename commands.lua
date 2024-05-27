local pickup_duration = 20
local dropoff_duration = 20

local commands = {}

---@class StopCommandWithSubtype : Command.defines_command_stop
---@field subtype string Subtype of the command

---comments
---@param position MapPosition
---@return Command.defines_command_go_to_location go_to_command
function commands.go_to_command(position)
    return {
        type = defines.command.go_to_location,
        destination = position,
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

---@class DropoffCommand : StopCommandWithSubtype
---@field item string
---@field amount integer

---comments
---@param dropoff_request any
---@return DropoffCommand
function commands.dropoff_command(dropoff_request)
    return {
        type = defines.command.stop,
        subtype = "dropoff",
        distraction= defines.distraction.none,
        ticks_to_wait = dropoff_duration,
        item = dropoff_request.item,
        amount = dropoff_request.amount
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
---@param build_item_request BuildItemRequest
---@return PickupV2Command
function commands.pickup_v2_command(build_item_request)
    return {
        type = defines.command.stop,
        subtype = "pickup",
        distraction= defines.distraction.none,
        ticks_to_wait = pickup_duration,
        item = build_item_request.ingredient.name,
        amount = build_item_request.ingredient.amount
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
        ghost_id = build_item_request.ghost_id,
        ghost_pos = build_item_request.ghost_pos
    }
end

return commands