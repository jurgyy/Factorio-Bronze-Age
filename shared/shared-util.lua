local shared_util = {}

---@param prototype data.ResourceEntityPrototype|data.TreePrototype
function shared_util.get_proxy_name(prototype)
    if prototype.type == "tree" then
        return "ba-attack-proxy-tree"
    end
    if prototype.type == "resource" then
        return "ba-attack-proxy-"..prototype.name
    end
    error("Unknown type")
end

return shared_util