local flib_bounding_box = require("__flib__/bounding-box")

local Queue = require("ba-queue")
local util = require("ba-util")
local ba_worker = require("worker")
local ba_request_handler = require("requestHandler")
local ba_requests = require("requests")
local ba_construction = require("construction")


script.on_init(function()
    global.request_queue = Queue.new()
    global.constructions = {} --[[@as table<integer, Construction>]]
    global.destruction_ids = {}
end)

local function test_add_pickup_request()
    local request = {
        type = "pickup-drop",
        pickup = {x = 25.5, y = 1.5},
        item = "stone-furnace",
        amount = 1,
        dropoff = {x = 25.5, y = 14.5},
        surface_index = global.the_worker.surface.index -- TODO surface
    }
    ba_request_handler.add_request(request)
end

local function test_request_item(item_name)
    local request = {
        type = "request-item",
        dropoff = {x = 25.5, y = 14.5},
        item = item_name,
        amount = 5,
        surface_index = game.surfaces[1].index -- TODO surface
    }
    ba_request_handler.add_request(request)
end

local function pol_work()
    if global.request_queue == nil then
        -- todo can be removed
        global.request_queue = Queue.new()
    end

    if not ba_worker.can_spawn() then
        return
    end

    local request = requests.get_request()
    if not request then
        util.print("no requests")
        return
    end
    ba_request_handler.handle_request(request)
end

local function request_item_console_command(command)
    if command.parameter then
        --game.print(command.parameter)
        test_request_item(command.parameter)
    end
end

---comment
---@param event EventData.on_built_entity
local function set_ghost_requests(event)
    ba_construction.new(event.created_entity)
end

---comments
---@param event EventData.on_entity_destroyed
local function entity_destroyed_event(event)
    -- todo will also get called when it's finished
    game.print("Entity destroyed")
    ghost_id = global.destruction_ids[event.registration_number]
    if not ghost_id then
        error("ghost_id not found")
        return
    end
    ba_requests.cancel_build_requests(ghost_id)
    global.destruction_ids[event.registration_number] = nil

    local construction = global.constructions[ghost_id]
    if construction then
        for item, count in pairs(construction.current) do
            game.surfaces[construction.surface_index].spill_item_stack(
                construction.position,
                {name = item, count = count}
            )
        end
    end
    global.constructions[ghost_id] = nil
end

local function foo(command)
    global.worker = nil
    --local player = game.players[command.player_index]
    --player.surface.spill_item_stack(player.position, {name = "copper-plate", count=10}, false, "neutral", true)
end

commands.add_command("ba-test", nil, foo)

commands.add_command("ba-set-request", nil, test_add_pickup_request)
commands.add_command("ba-request-item", nil, request_item_console_command)

script.on_event(defines.events.on_built_entity, set_ghost_requests, {
    {filter = "name", name = "entity-ghost"},
    {filter = "type", type = "entity-ghost", mode = "and"}
})

script.on_event(defines.events.on_entity_destroyed, entity_destroyed_event)


--script.on_event(defines.events.on_ai_command_completed, on_ai_command_completed)
script.on_nth_tick(30, pol_work)

local handler = require("event_handler")
handler.add_lib(require("worker"))
