local flib_bounding_box = require("__flib__/bounding-box")

local util = require("util")

util.path_name = "ba-path"


util.highlight_bbox = function(surface, bbox, color)
  if color == nil then
      color = {r = 0, g = 1, b = 0, a = 1}
  end
  rendering.draw_rectangle {
      color = color,
      left_top = bbox.left_top,
      right_bottom = bbox.right_bottom,
      time_to_live = 120,
      surface = surface
  }
end

util.highlight_position = function(surface, position, color, snap)
  if snap == nil then
    snap = false
  end
  
  local bbox = flib_bounding_box.from_position(position, snap)
  bbox = flib_bounding_box.resize(bbox, -0.02)
  util.highlight_bbox(surface, bbox, color)
end

util.highlight_radius = function(surface, position, radius, color)
  local bbox = flib_bounding_box.from_dimensions(position, radius * 2, radius * 2)
  util.highlight_bbox(surface, bbox, color)
end


---Check if a given position has a ba-path tile
---@param surface LuaSurface
---@param x number
---@param y number
---@return boolean
local function is_path_tile_xy(surface, x, y)
  return surface.get_tile(x, y).name == util.path_name
end

---Is the MapPosition is a ba-path
---@param surface LuaSurface
---@param position MapPosition
---@return boolean
local function is_path_tile(surface, position)
  return surface.get_tile(position.x, position.y).name == util.path_name
end


util.get_all_positions_around = function(surface, area)
  local expanded = flib_bounding_box.resize(area, 1)
  util.highlight_bbox(surface, area)
  util.highlight_bbox(surface, expanded)

  local abs_left_top = {x = math.ceil(expanded.left_top.x) - 0.5, y = math.ceil(expanded.left_top.y) - 0.5}
  local abs_right_bottom = {x = math.ceil(expanded.right_bottom.x) - 0.5, y = math.ceil(expanded.right_bottom.y) - 0.5}

  util.highlight_radius(surface, abs_left_top, 0.2, {r = 1, b = 0, g = 0, a = 1})
  util.highlight_radius(surface, abs_right_bottom, 0.2, {r = 1, b = 0, g = 0, a = 1})

  local tiles = {}
  util.print("BB: "..game.table_to_json(area))
  util.print("LT: "..game.table_to_json(abs_left_top))
  util.print("BR: "..game.table_to_json(abs_right_bottom))
  for x = abs_left_top.x, abs_right_bottom.x do
    table.insert(tiles, {x = x, y = abs_left_top.y})
    table.insert(tiles, {x = x, y = abs_right_bottom.y})
  end

  for y = abs_left_top.y + 1, abs_right_bottom.y - 1 do
    table.insert(tiles, {x = abs_left_top.x, y = y})
    table.insert(tiles, {x = abs_right_bottom.x, y = y})
  end
  return tiles
end

---Check clockwise around an area (expanded by 1 tile) for ba-path tiles and return a list of the first tile of all unconnected tiles (without checking further away)
---@param surface LuaSurface
---@param area BoundingBox
---@return MapPosition[]
util.get_path_sets_around = function(surface, area)
  local check_tile = function(x, y, disjoint_tiles, jointed_set)
    local position = {x = x, y = y}
    local is_path = is_path_tile(surface, position)

    if (not jointed_set and is_path) then
      table.insert(disjoint_tiles, position)
      jointed_set = true
    elseif not is_path then
      jointed_set = false
    else
    end
    return jointed_set
  end

  local expanded = flib_bounding_box.resize(area, 1)
  local abs_left_top = {x = math.ceil(expanded.left_top.x) - 0.5, y = math.ceil(expanded.left_top.y) - 0.5}
  local abs_right_bottom = {x = math.ceil(expanded.right_bottom.x) - 0.5, y = math.ceil(expanded.right_bottom.y) - 0.5}

  local disjoint_tiles = {}

  -- first tile
  local first_tile_is_set = check_tile(abs_left_top.x + 1, abs_left_top.y, disjoint_tiles, false)
  local jointed_set = first_tile_is_set
  -- Top edge
  for x = abs_left_top.x + 2, abs_right_bottom.x do
    jointed_set = check_tile(x, abs_left_top.y, disjoint_tiles, jointed_set)
  end
  
  -- Right edge
  for y = abs_left_top.y + 1, abs_right_bottom.y do
    jointed_set = check_tile(abs_right_bottom.x, y, disjoint_tiles, jointed_set)
  end

  -- Bottom edge
  for x = abs_right_bottom.x - 1, abs_left_top.x, -1 do
    jointed_set = check_tile(x, abs_right_bottom.y, disjoint_tiles, jointed_set)
  end

  -- Left edge
  for y = abs_right_bottom.y - 1, abs_left_top.y, -1 do
    jointed_set = check_tile(abs_left_top.x, y, disjoint_tiles, jointed_set)
  end

  -- first and last are connected, delete the large element since they belong to the same set
  if first_tile_is_set and jointed_set and #disjoint_tiles > 1 then
    table.remove(disjoint_tiles, #disjoint_tiles)
  end
  return disjoint_tiles
end

---Find chests near position in an exponentially increasing radius up until max_range
---@param surface LuaSurface
---@param pos MapPosition
---@param insert boolean Insert the items or retrieve them?
---@param itemStack SimpleItemStack Item name and count to retrieve or store
---@param max_range? integer Max range to check. If nil defaults to 1000.
---@return LuaEntity? Chest The chest entity or nil if no chest is found
util.find_chest_exponential = function(surface, pos, insert, itemStack, max_range)
    max_range = max_range or 1000
    local radius = 10
    local checked = {}
  
    while radius <= max_range do
      local chests = surface.find_entities_filtered({
        position = pos,
        radius = radius,
        name = {"wooden-chest", "iron-chest", "steel-chest", "logistic-chest-passive-provider", "logistic-chest-active-provider", "logistic-chest-storage", "logistic-chest-buffer", "logistic-chest-requester"}
      })
  
      for _, chest in ipairs(chests) do
        if checked[chest.unit_number] then
          goto continue
        end
  
        if insert then
          if chest.can_insert(itemStack) then
            return chest
          end
        else
          local contents = chest.get_inventory(defines.inventory.chest).get_contents()
          local count = contents[itemStack.name] or 0
          if count >= itemStack.count then
            return chest
          end
        end
  
        checked[chest.unit_number] = true
        ::continue::
      end
  
      radius = radius * 10
    end
    return nil
  end

util.print = function(message)
  game.print(message, {sound = defines.print_sound.never})
end

return util