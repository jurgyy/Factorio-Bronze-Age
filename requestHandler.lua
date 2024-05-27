local flib_bounding_box = require("__flib__/bounding-box")


local util = require("ba-util")
local ba_worker = require("worker")
local ba_commands = require("commands")
local ba_requests = require("requests")

local handler = {}

local function find_chest(surface_index, item, amount)
    local surface = game.surfaces[surface_index]
    local bbox = flib_bounding_box.from_position({x = 0, y = 0}, true)
    bbox = flib_bounding_box.resize(bbox, 50)
    util.highlight_bbox(surface, bbox)

    local chests = surface.find_entities_filtered{
        area = bbox,
        --position = {x = 0, y = 0},
        --radius = 100,
        name = "wooden-chest"
    }

    local largest = nil
    local largest_amount = 0
    for _, chest in pairs(chests) do
        local inventory = chest.get_output_inventory()
        if inventory then
            local stack = inventory.find_item_stack(item)
            if stack then
                if stack.count >= amount then
                    return {chest, amount}
                elseif stack.count > largest_amount then
                    largest = chest
                    largest_amount = stack.count
                end
            end
        end
    end
    if largest then
        return {largest, largest_amount}
    end
    return nil
end

handler.handle_request_item_request = function(request)
    local result = find_chest(request.surface_index, request.item, request.amount)
    if not result then
        util.print("Couldn't find chest with item " .. request.item .. ". Adding it back to the queue")
        ba_requests.add_request(request)
        return
    end
    local chest, amount = result[1], result[2]
    if amount < request.amount then
        local remaining = table.deepcopy(request)
        remaining.amount = request.amount - amount
        util.print("Couldn't fulfil entire request. Adding request for remaining " .. remaining.amount .. " items")
        ba_requests.add_request(remaining)
    end

    local surface = game.surfaces[request.surface_index]
    local spawn_position = util.get_position(chest)
    local worker = ba_worker.spawn_unlimited(surface, spawn_position, game.players[1].force)

    util.highlight_position(surface, chest.position)
    util.highlight_position(surface, request.dropoff)
    local command = {
        type = defines.command.compound,
        structure_type = defines.compound_command.logical_and,
        distraction = defines.distraction.none,
        commands = {
            ba_commands.go_to_command(chest.position),
            ba_commands.pickup_command(request),
            ba_commands.go_to_command(request.dropoff),
            ba_commands.dropoff_command(request),
        }
    }
    if not worker then
        util.print("Adding request back on the queue")
        ba_requests.add_request(request)
        return
    end
    worker.command = command
    return worker
end

--- @class BuildItemRequest
--- @field type string Request type, equal to "build-item".
--- @field ingredient Ingredient Ingredient that this request handles
--- @field surface_index integer Surface index of the request
--- @field dropoff_area BoundingBox.0|BoundingBox.1 Area where the items can be delivered to
--- @field ghost_id integer unit_number for the ghost
--- @field ghost_pos MapPosition.0|MapPosition.1 position of the ghost entity

---comments
---@param request BuildItemRequest
handler.handle_build_item_request = function(request)
    local result = find_chest(request.surface_index, request.ingredient.name, request.ingredient.amount)
    if not result then
        util.print("Couldn't find chest with item " .. request.ingredient.name .. ". Adding it back to the queue")
        ba_requests.add_request(request)
        return
    end
    local source_chest, amount = result[1], result[2]
    if amount < request.ingredient.amount then
        local remaining = table.deepcopy(request)
        remaining.ingredient.amount = request.ingredient.amount - amount
        request.ingredient.amount = amount
        util.print("Couldn't fulfil entire request. Adding request for remaining " .. remaining.ingredient.amount .. " items")
        ba_requests.add_request(remaining)
    end

    local surface = game.surfaces[request.surface_index]
    local spawn_position = util.get_position(source_chest)
    local goal_position = util.get_path_near(surface, request.dropoff_area)
    local worker = ba_worker.spawn_unlimited(surface, spawn_position, game.players[1].force) -- TODO force

    util.highlight_position(surface, source_chest.position)
    util.highlight_position(surface, goal_position)
    local command = {
        type = defines.command.compound,
        structure_type = defines.compound_command.logical_and,
        distraction = defines.distraction.none,
        commands = {
            ba_commands.go_to_command(source_chest.position),
            ba_commands.pickup_v2_command(request),
            ba_commands.go_to_command(goal_position),
            ba_commands.dropoff_build_command(request),
        }
    }
    if not worker then
        util.print("Adding request back on the queue")
        ba_requests.add_request(request)
        return
    end
    worker.command = command
    return worker
end

---comments
---@param request BuildItemRequest|any
handler.handle_request = function(request)
    local worker
    if request.type == "pickup-drop" then
        worker = handler.handle_pickup_drop_request(request)
    elseif request.type == "request-item" then
        worker = handler.handle_request_item_request(request)
    elseif request.type == "build-item" then
        worker = handler.handle_build_item_request(request)
    else
        util.print("Unknown request type: " .. request.type)
        return
    end

    if not worker then
        --util.print("Retrieved no worker to execute command with")
        return
    end
    ba_worker.next_step{unit_number = worker.unit_number}
end



handler.handle_pickup_drop_request = function(request)
    error("Not implemented") -- todo
    util.print("Handling pickup-drop request")
    util.highlight_position(game.surfaces[request.surface_index], request.pickup)
    util.highlight_position(game.surfaces[request.surface_index], request.dropoff)
    current_command = {
        type = defines.command.compound,
        structure_type = defines.compound_command.logical_and,
        distraction = defines.distraction.none,
        commands = {
            ba_commands.go_to_command(request.pickup),
            ba_commands.pickup_command(current_request),
            ba_commands.go_to_command(request.dropoff),
            ba_commands.dropoff_command(current_request),
        }
    }
end

return handler