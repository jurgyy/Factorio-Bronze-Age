local Queue = require("ba-queue")

requests = {}

---comment
---@param ghost_entity LuaEntity
---@param ingredient Ingredient
---@return table A build-item request
requests.request_building_item = function(ghost_entity, ingredient)
    return {
        type = "build-item",
        ingredient = ingredient,
        surface_index = ghost_entity.surface_index,
        dropoff_area = ghost_entity.bounding_box,
        ghost_id = ghost_entity.unit_number,
        ghost_pos = ghost_entity.position
    }
end

requests.add_request = function(request)
    Queue.push_back(global.request_queue, request)
end

requests.get_request = function()
    local request = Queue.pop_front(global.request_queue)
    if not request then
        return
    end
    --game.print("request: " .. game.table_to_json(request))
    return request
end

requests.cancel_build_requests = function(ghost_id)
    local remove_index = {}
    for idx in Queue.iter(global.request_queue) do
        if global.request_queue[idx].ghost_id == ghost_id then
            -- index is adjusted for when elements are removed before it
            table.insert(remove_index, idx - #remove_index)
        end
    end

    for _, index in pairs(remove_index) do
        Queue.remove_at(global.request_queue, index)
    end
end

return requests