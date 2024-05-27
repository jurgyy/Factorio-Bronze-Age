local flib_bounding_box = require("__flib__/bounding-box")

local util = require("util")

util.path_name = "ba-path"

util.damage_type = function(name)
    if not data.raw["damage-type"][name] then
      data:extend{{type = "damage-type", name = name, localised_name = {name}}}
    end
    return name
end
  
util.ammo_category = function(name)
    if not data.raw["ammo-category"][name] then
      data:extend{{type = "ammo-category", name = name, localised_name = {name}}}
    end
    return name
end

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

util.highlight_position = function(surface, position, color)
  local bbox = flib_bounding_box.from_position(position, true)
  bbox = flib_bounding_box.resize(bbox, -0.02)
  util.highlight_bbox(surface, bbox, color)
end

local function add(p1, p2)
  return {x = p1.x + p2.x, y = p1.y + p2.y}
end

util.get_position = function(entity)
  local directions = {
      {x = 1, y = 0},
      {x = -1, y = 0},
      {x = 0, y = 1},
      {x = 0, y = -1},
  }

  for _, v in pairs(directions) do
      local position = add(entity.position, v)
      if (entity.surface.get_tile(position.x, position.y).name == util.path_name) then
          return position
      end
  end

  util.print("Not next to path")
end


local function check_position(surface, x, y)
  local top_tile = surface.get_tile(x, y)
  return top_tile.name == util.path_name
end

local function sign(number)
  return number > 0 and 1 or (number == 0 and 0 or -1)
end

local function absceil(x)
  return sign(x) * math.ceil(math.abs(x))
end

---Get the position of a ba-worker traversable tile surrounding a given area
---@param surface LuaSurface
---@param area BoundingBox
---@return MapPosition
util.get_path_near = function(surface, area)
    local expanded = flib_bounding_box.resize(area, 1)
    util.highlight_bbox(surface, area)
    util.highlight_bbox(surface, expanded)
    local abs_left_top = {x = absceil(expanded.left_top.x), y = absceil(expanded.left_top.y)}
    local abs_right_bottom = {x = absceil(expanded.right_bottom.x), y = absceil(expanded.right_bottom.y)}

  for x = abs_left_top.x, abs_right_bottom.x do
      -- Check the top edge
      if check_position(surface, x, abs_left_top.y) then
        return {x = x, y = abs_left_top.y}
      end

      -- Check the bottom edge
      if check_position(surface, x, abs_right_bottom.y) then
        return {x = x, y = abs_right_bottom.y}
      end
  end

  for y = abs_left_top.x + 1, abs_right_bottom.y - 1 do
      -- Check the left edge
      if check_position(surface, abs_left_top.x, y) then
        return {x = abs_left_top.x, y}
      end

      -- Check the right edge
      if check_position(surface, abs_right_bottom.x, y) then
        return {x = abs_right_bottom.x, y}
      end
  end
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