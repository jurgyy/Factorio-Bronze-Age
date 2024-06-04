local flib_bounding_box = require("__flib__/bounding-box")
local pathfinding       = require("pathfinding")
local PathfindingCollection = require("PathfindingCollection")


local util = require("ba-util")
local ba_worker = require("worker")
local ba_commands = require("commands")
local ba_requests = require("requests")

local handler = {}

---@alias ChestWithAmount {chest: LuaEntity, amount: integer}

---Return a list of {chest_entity, amount} pairs consiting of chests that contain the requested item and how much
---@param surface_index integer Surface index
---@param item string Item name
---@param amount integer Requested amount
---@param position MapPosition Center of the to search area
---@param search_radius number Range to search for chests
---@return ChestWithAmount[] chests_with_amount
local function find_chests(surface_index, item, amount, position, search_radius)
    local surface = game.surfaces[surface_index]
    local bbox = flib_bounding_box.from_position(position, true)
    bbox = flib_bounding_box.resize(bbox, search_radius)
    util.highlight_bbox(surface, bbox)

    local chests = surface.find_entities_filtered{
        name = "wooden-chest",
        position = position,
        radius = search_radius
    }

    chests_with_amount = {}
    for _, chest in pairs(chests) do
        local inventory = chest.get_output_inventory()
        if inventory then
            local stack = inventory.find_item_stack(item)
            if stack then
                --if stack.count >= amount then
                    util.highlight_position(game.surfaces[surface_index], chest.position)
                    table.insert(chests_with_amount, {chest = chest, amount = stack.count})
                --end
            end
        end
    end

    return chests_with_amount
end

---comments
---@param request BuildItemRequest
handler.handle_build_item_request = function(request)
    if not request.ghost.valid then
        return
    end

    local chests_with_amount = find_chests(request.ghost.surface_index, request.ingredient.name, request.ingredient.amount, request.ghost.position, 100)
    if not chests_with_amount or not chests_with_amount[1] then
        util.print("Couldn't find chest with item " .. request.ingredient.name .. ". Adding it back to the queue")
        ba_requests.add_request(request)
        return
    end

    local pf_collection = PathfindingCollection.new(
        request.ghost.surface_index,
        request.ingredient.name,
        request.ingredient.amount,
        game.entity_prototypes["ba-worker"],
        request.ghost
    )
    if not pf_collection then
        error("Not implemented")
    end

    for _, chest_with_amount in ipairs(chests_with_amount) do
        pf_collection:add_paths_from_entity(chest_with_amount.chest, chest_with_amount.amount)
    end

    if not pf_collection:request_next() then
        util.print("No paths, adding it back to the queue")
        requests.add_request(request)
    end
end

---@param request ItemDeliveryRequest
handler.handle_item_delivery_request = function(request)
    if not request.ghost.valid then
        return
    end

    if not request.chest.valid then
        error("Not implemented")
    end
    local worker = ba_worker.spawn_unlimited(request.surface, request.start, game.players[1].force, request) -- TODO force

    if not worker then
        util.print("Adding request back on the queue")
        ba_requests.add_request(request)
        return
    end

    local command = {
        type = defines.command.compound,
        structure_type = defines.compound_command.logical_and,
        distraction = defines.distraction.none,
        commands = {
            ba_commands.pickup_v2_command(request),
            ba_commands.go_to_command(request.goal, 0.5),
            ba_commands.dropoff_build_command(request),
        }
    }

    worker.command = command
    return worker
end

---comments
---@param request GoToRequest
---@return UnitData|nil
handler.handle_go_to_request = function(request)
    local worker = ba_worker.spawn_unlimited(
        request.surface,
        {x = request.position.x + 15, y = request.position.y},
        game.players[1].force,
        request
    ) -- TODO force

    local command = {
        type = defines.command.compound,
        structure_type = defines.compound_command.logical_and,
        distraction = defines.distraction.none,
        commands = {
            ba_commands.go_to_command(request.position, 2),
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
---@param request Request
handler.handle_request = function(request)
    local worker --[[@as UnitData]]
    if request.type == "build-item" then
        --- @cast request BuildItemRequest
        worker = handler.handle_build_item_request(request)
    elseif request.type == "delivery" then
        --- @cast request ItemDeliveryRequest
        worker = handler.handle_item_delivery_request(request)
    elseif request.type == "go-to" then
        --- @cast request GoToRequest
        worker = handler.handle_go_to_request(request)
    else
        util.print("Unknown request type: " .. request.type)
        return
    end

    if not worker then
        --util.print("Retrieved no worker to execute command with")
        return
    end
    ba_worker.next_step{unit_number = worker.entity.unit_number}
end

return handler