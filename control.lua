local flib_bounding_box = require("__flib__/bounding-box")

local Queue = require("ba-queue")
local util = require("ba-util")
local ba_worker = require("worker")
local ba_request_handler = require("requestHandler")
local ba_requests = require("requests")
local ba_construction = require("construction")

local item_recipe_cache = {}

---@alias SurfaceIndex integer

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

local function initialize_globals()
    game.print("Initializing")
    global.request_queue = global.request_queue or Queue.new()
    
    --[[@type table<integer, Construction>]]
    global.constructions = global.constructions or {}
    
    global.destruction_ids = global.destruction_ids or {}
    
    --[[@type WorkerData]]
    global.worker_data = global.worker_data or {
        n_workers = 0,
        max_workers = 2,
        workers = {}
    }
    --[[@type PathfindingRequests]]
    global.pathfinding_requests = global.pathfinding_requests or {}
    --[[@type table<integer, DisjointSet>]]
    global.tiles_disjoint_sets = global.tiles_disjoint_set or {}

    --[[@type CampScriptData?]]
    global.camps = global.camps or {}
    
    --[[@type CampWorkerScriptData?]]
    global.camp_workers = global.camp_workers or {}

    --[[@type HousingScriptData?]]
    global.housing = global.housing or {}
end

script.on_init(function()
    initialize_globals()
end)

script.on_configuration_changed(function()
    game.print("Config changed")
    initialize_globals()
end)


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
        --util.print("no requests")
        return
    end
    ba_request_handler.handle_request(request)
end

---comment
---@param event EventData.on_built_entity
local function set_ghost_requests(event)
    -- local around = util.get_all_positions_around(event.created_entity.surface, event.created_entity.bounding_box)
    -- for i, pos in ipairs(around) do
    --     util.highlight_radius(event.created_entity.surface, pos, 0.2, {r = 0, b = 1/#around * i, g = 0, a = 0.5})
    -- end
    if true then return end

    if event.created_entity.name == "wooden-chest" then
        return
    end

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
        --error("ghost_id not found")
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

---comments
---@param event EventData.on_script_path_request_finished
local function handle_path_request(event)
    local path = global.pathfinding_requests[event.id]
    if not path then
        util.print("Path " .. event.id .. " request not found")
        return
    end
    
    global.pathfinding_requests[event.id] = nil
    if event.try_again_later then
        util.print("Path " .. event.id .. ": try again later")
        path.collection:request_path(path)
        return
    end

    -- No path found: Request next
    if not event.path then
        util.print("Path " .. event.id .. ": No path found")
        local nxt = path.collection:request_next()
        if not nxt then
            ba_requests.add_request(ba_requests.request_building_item(path.collection.goal_entity, {name=path.collection.item_name, amount=path.collection.total_amount}))
        end
        util.highlight_position(game.surfaces[path.collection.surface_index], path.start, {r=1, b = 0, g = 0, a = 1})
        return
    end
    util.highlight_position(game.surfaces[path.collection.surface_index], path.start, {r=0, b = 0, g = 1, a = 1})
    util.highlight_position(game.surfaces[path.collection.surface_index], path.goal, {r=0, b = 0, g = 1, a = 1})


    -- Path is found: Add request for worker to deliver the item
    local remaining = math.min(path.amount or 1, path.collection.total_amount)
    local capacity = ba_worker.get_worker_capacity(path.collection.item_name)
    while remaining > 0 do
        local amount = math.min(remaining, capacity)
        if not amount or amount <= 0 then
            error("Amount cannot be 0 or smaller")
        end
        requests.add_request(requests.request_item_delivery(path, amount))
        remaining = remaining - amount
    end

    -- Not enough paths found: Request next
    if not path.collection:path_found_finished(path) then
        local nxt = path.collection:request_next()
        if not nxt then
            ba_requests.add_request(ba_requests.request_building_item(path.collection.goal_entity, {name=path.collection.item_name, amount=path.collection.total_amount - path.amount}))
            -- TODO add more to a request queue
        end
    end
end

local handler = require("event_handler")
handler.add_lib(require("script/camp-worker"))
handler.add_lib(require("script/camp"))
handler.add_lib(require("script/housing"))
handler.add_lib(require("script/worker-distribution"))
handler.add_lib(require("script/worker-compounds"))
handler.add_lib(require("script/paths"))

-- commands.add_command("ba-reinitialize", nil, initialize_globals)

-- script.on_event(defines.events.on_built_entity, set_ghost_requests)

-- script.on_event(defines.events.on_entity_destroyed, entity_destroyed_event)

-- script.on_event(defines.events.on_ai_command_completed, ba_worker.on_ai_command_completed)
-- script.on_event(defines.events.on_script_path_request_finished, handle_path_request)

-- script.on_nth_tick(30, pol_work)