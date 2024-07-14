util = require("ba-util")

---@class DisjointSetIndex
---@field x integer
---@field y integer

--- @class DisjointSet
--- @field parent table<integer, table<integer, DisjointSetIndex>> table[x_self][y_self] -> {x: x_parent, y: y_parent}
--- @field rank table<integer, table<integer, integer>> table[x_self][y_self] -> rank
--- @field children table<integer, table<integer, DisjointSetIndex[]?>> table[x_self][y_self] -> child_index[]?
local DisjointSet = {}
DisjointSet.__index = DisjointSet
script.register_metatable("disjoint_set", DisjointSet)

--- @class TileOrPosition
--- @field tile? LuaTile
--- @field position? MapPosition

---Are the two positions equal?
---@param pos1 DisjointSetIndex?
---@param pos2 DisjointSetIndex?
local function equal(pos1, pos2)
    return pos1 == pos2 or (pos1 and pos2 and pos1.x == pos2.x and pos1.y == pos2.y)
end

---Creates a new DisjointSet
---@return DisjointSet
function DisjointSet.new()
    local self = setmetatable({}, DisjointSet)
    self.parent = {}
    self.rank = {}
    self.children = {}
    return self
end

---Transforms a MapPosition into an DisjointSetIndex
---@param map_position MapPosition
---@return DisjointSetIndex
function DisjointSet:get_index(map_position)
    return {
        x = math.floor(map_position.x or map_position[1]),
        y = math.floor(map_position.y or map_position[2])
    }
end

---@param position DisjointSetIndex? The index position
---@return DisjointSetIndex? parent The parent. Returns the index position if not found
function DisjointSet:get_parent(position)
    if not position then return nil end

    local x = self.parent[position.x]
    if not x then return nil end
    return x[position.y]
end

---@param position DisjointSetIndex The index position
---@param parent DisjointSetIndex? The parent
---@param add_child boolean?
function DisjointSet:set_parent(position, parent, add_child)
    add_child = add_child or add_child == nil -- nil -> true
    local parent_x = self.parent[position.x] or {}
    parent_x[position.y] = parent
    self.parent[position.x] = parent_x

    if self.children[position.x] and self.children[position.x][position.y] then
        for _, child in pairs(self.children[position.x][position.y]) do
            self:set_parent(child, parent)
        end
    end

    if add_child and parent and not equal(position, parent) then
        self:add_as_child(position, parent --[[@as DisjointSetIndex]])
    end
end

---@param child DisjointSetIndex
---@param parent DisjointSetIndex
function DisjointSet:add_as_child(child, parent)
    if not self.children[parent.x] then
        self.children[parent.x] = {}
    end
    
    if not self.children[parent.x][parent.y] then
        self.children[parent.x][parent.y] = {}
    end

    table.insert(self.children[parent.x][parent.y], child)
    
    if not self.children[child.x] then
        return
    end

    self.children[child.x][child.y] = nil
    if not next(self.children[child.x]) then
        self.children[child.x] = nil
    end
end

---@param position DisjointSetIndex The index position
---@return integer rank The position's rank
function DisjointSet:get_rank(position)
    local rank_x = self.rank[position.x]
    if not rank_x then return 0 end
    return rank_x[position.y] or 0
end

---@param position DisjointSetIndex The index position
---@param value integer The position's rank
function DisjointSet:set_rank(position, value)
    local x = self.rank[position.x] or {}
    x[position.y] = value
    self.rank[position.x] = x
end


---Is the index in the disjointed set? Returns the index of itself if it is alone.
---The index of its parent if in a group or nil if it is not in the entire set.
---@param index DisjointSetIndex?
---@return DisjointSetIndex?
function DisjointSet:find(index)
    return self:get_parent(index)
end

---Adds a connection between two indices
---@param index1 DisjointSetIndex
---@param index2 DisjointSetIndex
---@param add_child boolean?
function DisjointSet:union(index1, index2, add_child)
    local root1 = self:find(index1)
    local root2 = self:find(index2)
    if root1 and root2 and not equal(root1, root2) then
        local rank1 = self:get_rank(root1)
        local rank2 = self:get_rank(root2)
        if rank1 > rank2 then
            self:set_parent(root2, root1, add_child)
        elseif rank1 < rank2 then
            self:set_parent(root1, root2, add_child)
        else
            self:set_parent(root2, root1, add_child)
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
    position = self:get_index(position)
    self:add_index(position)
end

function DisjointSet:add_index(index)
    if self:get_parent(index) == nil then
        self:set_parent(index, index)
        -- We do not initialize the rank since the getter already returns 0 if it's not stored
    end

    self:union(index, {x = index.x - 1, y = index.y}, false)
    self:union(index, {x = index.x + 1, y = index.y}, false)
    self:union(index, {x = index.x, y = index.y - 1}, false)
    self:union(index, {x = index.x, y = index.y + 1}, false)
end

---Removes a possition from the disjoint set and then recalculates the disjoint set for all childeren of the root parent. Extremely inefficient.
---@param tile_or_position TileOrPosition
function DisjointSet:remove(tile_or_position)
    local position = tile_or_position.position or tile_or_position.tile.position
    if not position then
        util.print("Cannot add value: no tile or position given")
        return
    end
    position = self:get_index(position)
    
    local parent = self:get_parent(position)
    local children = parent and self.children[parent.x] and self.children[parent.x][parent.y]
    self.parent[position.x][position.y] = nil
    if children then

        for i, child in pairs(children) do
            if equal(child, position) then
                children[i] = nil
            end

            self.parent[child.x][child.y] = nil
        end

        for _, child in pairs(children) do
            self:add_index(child)
        end
    end
end

---Are two positions connect
---@param pos1 MapPosition
---@param pos2 MapPosition
---@return boolean
function DisjointSet:isConnected(pos1, pos2)
    pos1 = self:get_index(pos1)
    pos2 = self:get_index(pos2)
    if self:get_parent(pos1) == nil or self:get_parent(pos2) == nil then
        return false
    end
    return self:find(pos1) == self:find(pos2)
end

return DisjointSet
