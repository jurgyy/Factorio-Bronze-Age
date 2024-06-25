---@alias HousingDefineName 
---| "shacks"
---| "hut"
---| "cottage"
---| "abodes"
---| "domus"
---| "courtyard"
---| "manor"
---| "villa"
---| "estate"

---@class HousingDefine
---@field workers integer Number of workers this housing houses
---@field upgrades_to HousingDefineName? Name of the housing this upgrades to
---@field upgrades_from HousingDefineName? Name of the housing this upgrades from

---@alias HousingDefines table<HousingDefineName, HousingDefine>

---@type HousingDefines
return {
    ["shacks"] = {
        workers = 5,
        upgrades_to = nil--"hut"
    },
    ["hut"] = {
        workers = 10,
        upgrades_from = "shacks",
        upgrades_to = "cottage",
    },
    ["cottage"] = {
        workers = 15,
        upgrades_from = "shacks",
        upgrades_to = "abodes",
    },
    ["abodes"] = {
        workers = 20,
        upgrades_from = "cottage",
        upgrades_to = "domus",
    },
    ["domus"] = {
        workers = 25,
        upgrades_from = "abodes",
        upgrades_to = "courtyard",
    },
    ["courtyard"] = {
        workers = 30,
        upgrades_from = "domus",
        upgrades_to = "manor",
    },
    ["manor"] = {
        workers = 35,
        upgrades_from = "courtyard",
        upgrades_to = "villa",
    },
    ["villa"] = {
        workers = 40,
        upgrades_from = "manor",
        upgrades_to = "estate",
    },
    ["estate"] = {
        workers = 50,
        upgrades_from = "villa",
    },
}