---@alias CampDefinesResourceType "resource"|"tree"

---@class CampDefinesCamp
---@field mining_radius number The camp's search radius
---@field mining_radius_offset number How far in front of the camp the mining area starts
---@field capacity integer The number of items can be stored in the camp before halting work
---@field drop_offset table<number, number> TODO idk
---@field worker_name string Name of the entity prototype associated with this camp
---@field recipes table<string, CampDefineRecipe> Table to map the camps recipe name to the resulting resource name and targeting resources
---@field crafting_categories string[] All crafting categories for this camp

---@class CampDefineRecipe
---@field result string
---@field store_amount integer Amount of the resource that can be stored in the camp
---@field targets string[]
---@field carry_count integer How much of this resource can a worker haul in one go

---@class CampDefinesWorker
---@field mining_interval integer
---@field mining_damage integer
---@field range number Attack range of the worker

---@class CampDefinesResource
---@field category string Recipe category
---@field type CampDefinesResourceType Type of resource
---@field visual_type CampDefinesResourceType? Type that the resource sounds and looks like. If nil it falls back to type

---@class CampDefines
---@field camps table<string, CampDefinesCamp>
---@field workers table<string, CampDefinesWorker>
---@field resources table<string, CampDefinesResource>

---@alias CampSupportedEntityPrototypes data.TreePrototype|data.ResourceEntityPrototype

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
                ["loggers-camp-wood"] = {
                    result = "wood",
                    store_amount = 250,
                    targets = {"wood", "ba-fallen-tree-resource"},
                    carry_count = 3,
                }
            },
        },
        ["mining-camp"] = {
            mining_radius = 25 + 0.5,
            mining_radius_offset = 2,
            capacity = 100,
            drop_offset = {0, 0},
            worker_name = "worker-miner",
            crafting_categories = {"mining"},
            recipes = {
                ["mining-camp-coal"] = {
                    result = "coal",
                    store_amount = 250,
                    targets = {"coal"},
                    carry_count = 3,
                }
            },
        }
    },
    workers = {
        ["worker-logger"] = {
            mining_interval = math.floor(26 * 1.5),
            mining_damage = 5,
            range = 1
        },
        ["worker-miner"] = {
            mining_interval = math.floor(26 * 1.5),
            mining_damage = 5,
            range = 0.5
        }
    },
    resources = {
        ["wood"] = {
            category = "logging",
            type = "tree"
        },
        ["ba-fallen-tree-resource"] = {
            category = "logging",
            type = "resource",
            visual_type = "tree"
        },
        ["coal"] = {
            category = "mining",
            type = "resource"
        }
    }
}

return data