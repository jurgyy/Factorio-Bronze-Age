local flib_bounding_box = require("__flib__/bounding-box")

local Queue = require("ba-queue")
local util = require("ba-util")
local ba_worker = require("worker")
local ba_request_handler = require("requestHandler")
local ba_requests = require("requests")
local ba_construction = require("construction")

local item_recipe_cache = {}

---Returns the recipe that produces a given item
---@param item_name string Name of an item
---@return LuaRecipePrototype|nil recipe The recipe for the item
local function get_item_recipe(item_name)
    if item_recipe_cache[item_name] then
        return game.recipe_prototypes[item_recipe_cache[item_name]]
    end

    for _, recipe in pairs(game.recipe_prototypes) do
        for _, product in pairs(recipe.products) do
            if product.name == item_name then
                item_recipe_cache[item_name] = recipe.name
                return recipe
            end
        end
    end
    return nil
end

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
    local count = 1
    local ghost_entity
    local item
    if event.created_entity.name == "entity-ghost" and event.created_entity.type == "entity-ghost" then
        ghost_entity = event.created_entity
        if event.created_entity.ghost_prototype.items_to_place_this then
            item = event.created_entity.ghost_prototype.items_to_place_this[1]
        end
    else
        local surface = event.created_entity.surface
        local ghost_data = {
            name = "entity-ghost",
            ghost_name = event.created_entity.name,
            position = event.created_entity.position,
            direction = event.created_entity.direction,
            force = event.created_entity.force,
            create_build_effect_smoke = false
        }
        item = event.item

        if not event.created_entity.destroy() then
            error("Unable to destroy original entity")
        end
        
        ghost_entity = surface.create_entity(ghost_data)
        if not ghost_entity then
            util.print("Unable to create ghost entity " .. game.table_to_json(event.created_entity.position))
        end

        local inventory = game.players[event.player_index].get_inventory(defines.inventory.character_main)
        count = event.stack.count
        if inventory then
            inventory.insert( {name=event.item.name, count=count})
        end
    end

    if not ghost_entity then
        error("Unable to create ghost entity")
    end

    if not item then
        error("No item could place the entity " .. ghost_entity.ghost_name)
    end

    local recipe = get_item_recipe(item.name)
    if not recipe then
        error("No recipe found for item " .. item.name)
    end
    ba_construction.new(ghost_entity, recipe, count)
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

script.on_event(defines.events.on_built_entity, set_ghost_requests)

script.on_event(defines.events.on_entity_destroyed, entity_destroyed_event)


--script.on_event(defines.events.on_ai_command_completed, on_ai_command_completed)
script.on_nth_tick(30, pol_work)

local handler = require("event_handler")
handler.add_lib(require("worker"))
