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
        return prototypes.recipe[item_recipe_cache[item_name]]
    end

    for _, recipe in pairs(prototypes.recipe) do
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
    storage.request_queue = storage.request_queue or Queue.new()
    
    --[[@type table<integer, Construction>]]
    storage.constructions = storage.constructions or {}
    
    storage.destruction_ids = storage.destruction_ids or {}
    
    --[[@type WorkerData]]
    storage.worker_data = storage.worker_data or {
        n_workers = 0,
        max_workers = 2,
        workers = {}
    }
    --[[@type PathfindingRequests]]
    storage.pathfinding_requests = storage.pathfinding_requests or {}
    --[[@type table<integer, DisjointSet>]]
    storage.tiles_disjoint_sets = storage.tiles_disjoint_set or {}

    --[[@type CampScriptData?]]
    storage.camps = storage.camps or {}
    
    --[[@type CampWorkerScriptData?]]
    storage.camp_workers = storage.camp_workers or {}

    --[[@type HousingScriptData?]]
    storage.housing = storage.housing or {}
end

script.on_init(function()
    initialize_globals()
end)

script.on_configuration_changed(function()
    game.print("Config changed")
    initialize_globals()
end)


local function pol_work()
    if storage.request_queue == nil then
        -- todo can be removed
        storage.request_queue = Queue.new()
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
    -- local around = util.get_all_positions_around(event.entity.surface, event.entity.bounding_box)
    -- for i, pos in ipairs(around) do
    --     util.highlight_radius(event.entity.surface, pos, 0.2, {r = 0, b = 1/#around * i, g = 0, a = 0.5})
    -- end
    if true then return end

    if event.entity.name == "wooden-chest" then
        return
    end

    local count = 1
    local ghost_entity
    local item
    if event.entity.name == "entity-ghost" and event.entity.type == "entity-ghost" then
        ghost_entity = event.entity
        if event.entity.ghost_prototype.items_to_place_this then
            item = event.entity.ghost_prototype.items_to_place_this[1]
        end
    else
        local surface = event.entity.surface
        local ghost_data = {
            name = "entity-ghost",
            ghost_name = event.entity.name,
            position = event.entity.position,
            direction = event.entity.direction,
            force = event.entity.force,
            create_build_effect_smoke = false
        }
        item = event.item

        if not event.entity.destroy() then
            error("Unable to destroy original entity")
        end
        
        ghost_entity = surface.create_entity(ghost_data)
        if not ghost_entity then
            util.print("Unable to create ghost entity " .. helpers.table_to_json(event.entity.position))
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
---@param event EventData.on_object_destroyed
local function entity_destroyed_event(event)
    -- todo will also get called when it's finished
    game.print("Entity destroyed")
    ghost_id = storage.destruction_ids[event.registration_number]
    if not ghost_id then
        --error("ghost_id not found")
        return
    end
    ba_requests.cancel_build_requests(ghost_id)
    storage.destruction_ids[event.registration_number] = nil

    local construction = storage.constructions[ghost_id]
    if construction then
        for item, count in pairs(construction.current) do
            game.surfaces[construction.surface_index].spill_item_stack{
                position = construction.position,
                stack = {name = item, count = count}
            }
        end
    end
    storage.constructions[ghost_id] = nil
end

---comments
---@param event EventData.on_script_path_request_finished
local function handle_path_request(event)
    local path = storage.pathfinding_requests[event.id]
    if not path then
        util.print("Path " .. event.id .. " request not found")
        return
    end
    
    storage.pathfinding_requests[event.id] = nil
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
            ba_requests.add_request(ba_requests.request_building_item(
                path.collection.goal_entity,
                {
                    type = "item",
                    name = path.collection.item_name,
                    amount = path.collection.total_amount
                }
            ))
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

    -- Not enough pathsfound: Request next
    if not path.collection:path_found_finished(path) then
        local nxt = path.collection:request_next()
        if not nxt then
            ba_requests.add_request(ba_requests.request_building_item(path.collection.goal_entity,
                {
                    type = "item",
                    name = path.collection.item_name,
                    amount = path.collection.total_amount - path.amount
                }
            ))
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
handler.add_lib(require("script/path-network"))
handler.add_lib(require("script/path-tiles"))
handler.add_lib(require("script/gui"))

-- commands.add_command("ba-reinitialize", nil, initialize_globals)

-- script.on_event(defines.events.on_built_entity, set_ghost_requests)

-- script.on_event(defines.events.on_entity_destroyed, entity_destroyed_event)

-- script.on_event(defines.events.on_ai_command_completed, ba_worker.on_ai_command_completed)
-- script.on_event(defines.events.on_script_path_request_finished, handle_path_request)

-- script.on_nth_tick(30, pol_work)