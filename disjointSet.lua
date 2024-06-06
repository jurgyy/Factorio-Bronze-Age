util = require("ba-util")

--- @class DisjointSet
--- @field parent table<integer, table<integer, MapPosition>>
--- @field rank table<integer, table<integer, integer>>
local DisjointSet = {}
DisjointSet.__index = DisjointSet
script.register_metatable("disjoint_set", DisjointSet)

--- @class TileOrPosition
--- @field tile? LuaTile
--- @field position? MapPosition

--- @alias Index string

---Creates a new DisjointSet
---@return DisjointSet
function DisjointSet.new()
    local self = setmetatable({}, DisjointSet)
    self.parent = {}
    self.rank = {}
    return self
end

---@param position MapPosition? The index position
---@return MapPosition? parent The parent. Returns the index position if not found
function DisjointSet:get_parent(position)
    if not position then return nil end

    local x = self.parent[position.x]
    if not x then return nil end
    return x[position.y]
end

---@param position MapPosition The index position
---@param parent MapPosition? The parent
function DisjointSet:set_parent(position, parent)
    local parent_x = self.parent[position.x] or {}
    parent_x[position.y] = parent
    self.parent[position.x] = parent_x
end

---@param position MapPosition The index position
---@return integer rank The position's rank
function DisjointSet:get_rank(position)
    local rank_x = self.rank[position.x]
    if not rank_x then return 0 end
    return rank_x[position.y] or 0
end

---@param position MapPosition The index position
---@param value integer The position's rank
function DisjointSet:set_rank(position, value)
    local x = self.rank[position.x] or {}
    x[position.y] = value
    self.rank[position.x] = x
end

---Are the two positions equal?
---@param pos1 MapPosition?
---@param pos2 MapPosition?
local function equal(pos1, pos2)
    return pos1 == pos2 or (pos1 and pos2 and pos1.x == pos2.x and pos1.y == pos2.y)
end

---Is the index in the disjointed set? Returns the index of itself if it is alone.
---The index of its parent if in a group or nil if it is not in the entire set.
---@param index MapPosition?
---@return MapPosition?
function DisjointSet:find(index)
    local parent = self:get_parent(index)
    if not equal(parent, index) and index then
        self:set_parent(index, self:find(parent))
    end
    return self:get_parent(index)
end

---Adds a connection between two indices
---@param index1 MapPosition
---@param index2 MapPosition
function DisjointSet:union(index1, index2)
    local root1 = self:find(index1)
    local root2 = self:find(index2)
    if root1 and root2 and not equal(root1, root2) then
        local rank1 = self:get_rank(root1)
        local rank2 = self:get_rank(root2)
        if rank1 > rank2 then
            self:set_parent(root2, root1)
        elseif rank1 < rank2 then
            self:set_parent(root1, root2)
        else
            self:set_parent(root2, root1)
            self:set_rank(root1, rank1 + 1)
        end
    end
end

---Add an element to the disjointed set
---@param tile_or_position TileOrPosition
function DisjointSet:add(tile_or_position)
    local position = tile_or_position.position or tile_or_position.tile.position
    if not position then
        util.print("Cannot add value: no tile or position given")
        return
    end
    position = {x = math.floor(position.x), y = math.floor(position.y)}
    
    if self:get_parent(position) == nil then
        self:set_parent(position, position)
        -- We do not initialize the rank since the getter already returns 0 if it's not stored
    end

    self:union(position, {x = position.x - 1, y = position.y})
    self:union(position, {x = position.x + 1, y = position.y})
    self:union(position, {x = position.x, y = position.y - 1})
    self:union(position, {x = position.x, y = position.y + 1})
end

---Are two positions connect
---@param pos1 MapPosition
---@param pos2 MapPosition
---@return boolean
function DisjointSet:isConnected(pos1, pos2)
    pos1 = {x = math.floor(pos1.x), y = math.floor(pos1.y)}
    pos2 = {x = math.floor(pos2.x), y = math.floor(pos2.y)}
    if self:get_parent(pos1) == nil or self:get_parent(pos2) == nil then
        return false
    end
    return self:find(pos1) == self:find(pos2)
end

return DisjointSet
