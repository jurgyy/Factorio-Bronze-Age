util = require("ba-util")

--- @class DisjointSet
--- @field parent table<Index, Index>
--- @field rank table<Index, integer>
local DisjointSet = {}
DisjointSet.__index = DisjointSet
script.register_metatable("disjoint_set", DisjointSet)

--- @class TileOrPosition
--- @field tile? LuaTile
--- @field position? MapPosition

--- @alias Index string

---Get the index given two integers
---@param x integer
---@param y integer
---@return Index
local function get_index(x, y)
    return x .. "," .. y
end


-- Szudzik's pairing function to uniquely map (int32, int32) -> int64
-- local function get_index(x, y)
--     local A, B
--     if x >= 0 then
--         A = 2 * x
--     else
--         A = -2 * x - 1
--     end
--     if y >= 0 then
--         B = 2 * y
--     else
--         B = -2 * y - 1
--     end

--     local C
--     if A >= B then
--         C = (A * A + A + B) / 2
--     else
--         C = (A + B * B) / 2
--     end
--     if not (x < 0 and y < 0 or x >= 0 and y >= 0) then
--         C = -1 * C - 1
--     end
--     return C
-- end

---Creates a new DisjointSet
---@return DisjointSet
function DisjointSet.new()
    local self = setmetatable({}, DisjointSet)
    self.parent = {}
    self.rank = {}
    return self
end


---Is the index in the disjointed set? Returns the index of itself if it is alone.
---The index of its parent if in a group or nil if it is not in the entire set.
---@param index Index
---@return Index?
function DisjointSet:find(index)
    if self.parent[index] ~= index then
        self.parent[index] = self:find(self.parent[index])
    end
    return self.parent[index]
end

---Adds a connection between two indices
---@param index1 Index
---@param index2 Index
function DisjointSet:union(index1, index2)
    local rootX = self:find(index1)
    local rootY = self:find(index2)
    if rootX and rootY and rootX ~= rootY then
        if self.rank[rootX] > self.rank[rootY] then
            self.parent[rootY] = rootX
        elseif self.rank[rootX] < self.rank[rootY] then
            self.parent[rootX] = rootY
        else
            self.parent[rootY] = rootX
            self.rank[rootX] = self.rank[rootX] + 1
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
    local x = math.floor(position.x)
    local y = math.floor(position.y)
    
    local index = get_index(x, y)
    if self.parent[index] == nil then
        self.parent[index] = index
        self.rank[index] = 0
    end

    self:union(index, get_index(x - 1, y))
    self:union(index, get_index(x + 1, y))
    self:union(index, get_index(x, y - 1))
    self:union(index, get_index(x, y + 1))
end

---Are two positions connect
---@param pos1 MapPosition
---@param pos2 MapPosition
---@return boolean
function DisjointSet:isConnected(pos1, pos2)
    local index1 = get_index(math.floor(pos1.x), math.floor(pos1.y))
    local index2 = get_index(math.floor(pos2.x), math.floor(pos2.y))
    if self.parent[index1] == nil or self.parent[index2] == nil then
        return false
    end
    return self:find(index1) == self:find(index2)
end

return DisjointSet
