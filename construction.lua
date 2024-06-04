local ba_requests = require("requests")
local util = require("ba-util")

local ba_construction = {}


local function get_sticker_line(current, total, item_name) 
    return current .. "/" .. total .. " [item=" .. item_name .. "]" 
end

local function render_sticker_line(entity, text, v_offset)
    return rendering.draw_text {
        surface = entity.surface,
        target = entity,
        target_offset = {0, v_offset},
        text = text,
        only_in_alt_mode = true,
        forces = {entity.force},
        color = {r = 1, g = 1, b = 1},
        alignment = "center",
        vertical_alignment = "middle",
        scale = 1,
        use_rich_text = true
    }
end

--- @class Construction
--- @field renderings integer[] rendering entity id's
--- @field ingredients Ingredient ingredients
--- @field current table<string, integer> delivered items
--- @field surface_index integer Surface index of the construction
--- @field position MapPosition Position of the construction

---Create a new sticker for a ghost entity
---@param ghost_entity LuaEntity The ghost entity
---@param ingredients Ingredient[] The entity's ingredients
local function create_new_sticker(ghost_entity, ingredients)
    local offset_per_line = 0.4
    local offset = -(offset_per_line * #ingredients / 2) - offset_per_line
    renderings = {}
    for _, ingredient in ipairs(ingredients) do
        local text = get_sticker_line(0, ingredient.amount, ingredient.name)
        offset = offset + offset_per_line
        local id = render_sticker_line(ghost_entity, text, offset)

        table.insert(renderings, id)
    end

    construction = {
        renderings = renderings,
        ingredients = ingredients,
        current = {},
        surface_index = ghost_entity.surface_index,
        position = ghost_entity.position
    } --[[@as Construction]]
    global.constructions[ghost_entity.unit_number] = construction
end

local function update_sticker(entity)
    local construction = global.constructions[entity.unit_number]
    if construction and construction.renderings then
        for i, ingredient in ipairs(construction.ingredients) do
            local current = construction.current[ingredient.name]
            if current then
                local text = get_sticker_line(current, ingredient.amount, ingredient.name)
                rendering.set_text(construction.renderings[i], text)
            end
        end
        return
    end
    util.print("can't find construction")
end

---Register a new Construction object and add the sticker
---@param ghost_entity LuaEntity The ghost entity to be built
---@param recipe LuaRecipePrototype Name of the recipe that produces item that can place the ghost
---@param count integer Mutliplier on the cost. Is used for entities such as curved rails.
ba_construction.new = function(ghost_entity, recipe, count)
    local ingredients = recipe.ingredients
    if not ingredients then
        util.print("Recipe has no ingredients")
        return
    end
    local uid = script.register_on_entity_destroyed(ghost_entity)
    if not global.destruction_ids then
        global.destruction_ids = {}
    end
    global.destruction_ids[uid] = ghost_entity.unit_number

    for _, ingredient in ipairs(ingredients) do
        ingredient.amount = ingredient.amount * count
        ba_requests.add_request(ba_requests.request_building_item(ghost_entity, table.deepcopy(ingredient)))
    end

    create_new_sticker(ghost_entity, ingredients)
end

---Is the given construction completed
---@param construction Construction
local function is_completed(construction)
    for _, ingredient in ipairs(construction.ingredients) do
        if ingredient.amount ~= construction.current[ingredient.name] then
            return false
        end
    end
    return true
end

ba_construction.is_completed = function(ghost_id)
    local construction = global.constructions[ghost_id]
    if not construction then
        util.print("command.ghost_id not in constructions table")
        return nil
    end
    return is_completed(construction)
end

ba_construction.cancel = function(ghost_id)
    util.print("Canceling")
    requests.cancel_build_requests(ghost_id)

    global.constructions[ghost_id] = nil
end

---Find to find a ghost entity
---@param ghost_id integer
---@param surface LuaSurface
---@param position MapPosition
---@return LuaEntity|nil
ba_construction.find_ghost = function(ghost_id, surface, position)
    local ghosts = surface.find_entities_filtered{
        name = "entity-ghost",
        position = position
    }
    local ghost
    for _, g in ipairs(ghosts) do
        if g.unit_number == ghost_id then
            ghost = g
        end
    end

    return ghost
end

---comments
---@param ghost_id integer unit_number of the ghost entity
---@param surface LuaSurface Surface of the construction
---@param position MapPosition Position of the ghost entity
---@param item_stack SimpleItemStack Item stack of the delivered items
---@return boolean delivered
ba_construction.deliver_item = function(ghost_id, surface, position, item_stack)
    local construction = global.constructions[ghost_id]
    if not construction then
        util.print("command.ghost_id not in constructions table")
        return false
    end

    local ghost = ba_construction.find_ghost(ghost_id, surface, position)

    if not ghost then
        util.print("can't find ghost")
        return false
    end

    -- create dropoff text
    -- unit_data.surface.create_entity{
    --     name = "ba-dropoff-text",
    --     position = unit_data.entity.position,
    --     text = command.amount .. "x [item=" .. command.item .. "]",
    --     speed = 10,
    --     time_to_live = 20
    -- }

    local delivered = false
    for _, ingredient in ipairs(construction.ingredients) do
        if ingredient.name == item_stack.name then
            delivered = true
            construction.current[item_stack.name] = (construction.current[item_stack.name] or 0) + item_stack.count
            break
        end
    end
    if not delivered then
        util.print("Can't find item in construction ingredients")
        return false
    end
    
    if is_completed(construction) then
        global.constructions[ghost_id] = nil
        ghost.revive()
    else
        update_sticker(ghost)
    end
    return true
end

return ba_construction