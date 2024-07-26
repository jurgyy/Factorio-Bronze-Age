---Find and set the final destination of the graph
---@param graph table<integer, integer>
---@param current integer
---@param visited table<integer, boolean>
---@return integer final_destination
local function find_and_set_final_destination(graph, current, visited)
    local path = {}

    while graph[current] do
        if visited[current] then
            -- Circular dependency detected, select the first node in the cycle as the final destination
            local final_dest = current
            for _, v in ipairs(path) do
                graph[v] = final_dest
            end
            return final_dest
        end

        visited[current] = true
        table.insert(path, current)
        current = graph[current]
    end

    local final_dest = current
    for _, v in ipairs(path) do
        graph[v] = final_dest
    end
    return final_dest
end

---Condenses a graph of integers such that nodes in a chain all point to a single root parent.
---If a circular pattern is detected, one root is chosen.
---Example: {{[1] = 2, [2] = 3, [3] = 4}} returns {{[1] = 4, [2] = 4, [3] = 4}}
---@param graph table<integer, integer>
---@return table<integer, integer> condensed
local function condense_graph(graph)
    for src in pairs(graph) do
        local visited = {}
        find_and_set_final_destination(graph, src, visited)
    end

    local condensed_pairs = {}
    local seen = {}

    for src, dest in pairs(graph) do
        if src ~= dest and not seen[src] then
            condensed_pairs[src] = dest
            seen[src] = true
        end
    end

    return condensed_pairs
end

return condense_graph