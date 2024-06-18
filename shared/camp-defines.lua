---@alias CampDefinesResourceType "resource"|"tree"

---@class CampDefinesCamp
---@field mining_radius number The camp's search radius
---@field mining_radius_offset number How far in front of the camp the mining area starts
---@field capacity integer The number of items can be stored in the camp before halting work
---@field drop_offset table<number, number> TODO idk
---@field worker_name string Name of the entity prototype associated with this camp
---@field recipes table<string, string> Table to map the camps recipe name to the resource name
---@field crafting_categories string[] All crafting categories for this camp

---@class CampDefinesWorker
---@field mining_interval integer
---@field mining_damage integer

---@class CampDefinesResource
---@field carry_count integer How much of this resource can a worker haul in one go
---@field category string Recipe category
---@field type CampDefinesResourceType Type of resource

---@class CampDefines
---@field camps table<string, CampDefinesCamp>
---@field workers table<string, CampDefinesWorker>
---@field resources table<string, CampDefinesResource>

---@type CampDefines
local data = {
    camps = {
        ["loggers-camp"] = {
            mining_radius = 25 + 0.5,
            mining_radius_offset = 2,
            capacity = 100,
            drop_offset = {0, 0},
            worker_name = "worker-logger",
            crafting_categories = {"logging"},
            recipes = {
                ["loggers-camp-wood"] = "wood"
            }
        },
        ["mining-camp"] = {
            mining_radius = 25 + 0.5,
            mining_radius_offset = 2,
            capacity = 100,
            drop_offset = {0, 0},
            worker_name = "worker-miner",
            crafting_categories = {"mining"},
            recipes = {
                ["mining-camp-coal"] = "coal"
            }
        }
    },
    workers = {
        ["worker-logger"] = {
            mining_interval = math.floor(26 * 1.5),
            mining_damage = 5
        },
        ["worker-miner"] = {
            mining_interval = math.floor(26 * 1.5),
            mining_damage = 5
        }
    },
    resources = {
        ["wood"] = {
            carry_count = 3,
            category = "logging",
            type = "tree"
        },
        ["coal"] = {
            carry_count = 3,
            category = "mining",
            type = "resource"
        }
    }
}

return data