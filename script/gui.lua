local flib_gui = require("__flib__/gui")

local compounds = require("script/worker-compounds")
local camps = require("script/camp")
local worker_distribution = require("script/worker-distribution")
local priority_enum = require("script/worker-priority")

local function should_monitor_entity(entity)
    return entity.name == "pottery-workshop"
end

---@type table<integer, LuaEntity> t<player_index: entity>
local open_gui_entity = {}

---@class WorkerSidebarGui
---@field root LuaGuiElement
---@field worker_amount LuaGuiElement
---@field worker_total LuaGuiElement
---@field worker_total_required LuaGuiElement
---@field employment_key LuaGuiElement
---@field employment LuaGuiElement
---@field priority LuaGuiElement
---@field network_id LuaGuiElement

local sidebar_root_name = "sidebar-root"
local sidebar_amount_label_name = "sidebar-amount-label"
local sidebar_total_label_name = "sidebar-total-label"
local sidebar_total_required_label_name = "sidebar-total-required-label"
local sidebar_employed_key_label_name = "sidebar-employed-key-label"
local sidebar_employed_label_name = "sidebar-unemployed-label"
local sidebar_switch_name = "sidebar-priority-switch"
local network_id_label_name = "sidebar-network-label"

---@param parent LuaGuiElement
---@param entity LuaEntity
---@return WorkerSidebarGui sidebar
local function create_worker_sidebar(parent, entity)
    local gui
    local type = entity.type
    if type == "assembling-machine" then
        gui = defines.relative_gui_type.assembling_machine_gui
    elseif type == "inserter" then
        gui = defines.relative_gui_type.inserter_gui
    else
        error("Not supported gui type " .. type)
    end
    local sidebar = flib_gui.add(parent, {
        type = "frame",
        name = sidebar_root_name,
        caption = "Workers",
        direction = "vertical",
        anchor = {
            gui = gui,
            position = defines.relative_gui_position.left,
            --type = "assembling-machine"
        },
        children =
        {{
            type="frame", direction="vertical", style="ba_sidebar_frame",
            children = {
                {
                    type="flow", direction="horizontal", style="ba_sidebar_row", children = {
                        {type="label", caption="Workers:", style="heading_3_label"},
                        {type="empty-widget", style="flib_horizontal_pusher"},
                        {type="label", style="label", caption="-", name=sidebar_amount_label_name}
                    }
                },
                {
                    type="flow", direction="horizontal", style="ba_sidebar_row", children = {
                        {type="label", caption="Building Priority:", style="heading_3_label"}
                    }
                },
                {
                    type="flow", direction="horizontal", style="ba_sidebar_row", children = {
                        {type="label", style="label", caption="Low"},
                        {type="switch", style="switch", allow_none_state=true, name=sidebar_switch_name},
                        {type="label", style="label", caption="High"}
                    }
                },
                {type="empty-widget", style="flib_vertical_pusher"},
                {
                    type="flow", direction="horizontal", style="ba_sidebar_row", children = {
                        {type="label", caption="Total Workers:", style="heading_3_label"},
                        {type="empty-widget", style="flib_horizontal_pusher"},
                        {type="label", style="label", caption="-", name=sidebar_total_label_name}
                    }
                },
                {
                    type="flow", direction="horizontal", style="ba_sidebar_row", children = {
                        {type="label", caption="Total Required:", style="heading_3_label"},
                        {type="empty-widget", style="flib_horizontal_pusher"},
                        {type="label", style="label", caption="-", name=sidebar_total_required_label_name}
                    }
                },
                {
                    type="flow", direction="horizontal", style="ba_sidebar_row", children = {
                        {type="label", caption="Unemployed:", style="heading_3_label", name=sidebar_employed_key_label_name},
                        {type="empty-widget", style="flib_horizontal_pusher"},
                        {type="label", style="label", caption="-", name=sidebar_employed_label_name}
                    }
                },
                {
                    type="flow", direction="horizontal", style="ba_sidebar_row", children = {
                        {type="label", caption="Path Network:", style="heading_3_label"},
                        {type="empty-widget", style="flib_horizontal_pusher"},
                        {type="label", style="label", caption="-", name=network_id_label_name}
                    }
                }
            }
        }}
    })

    return {
        root = sidebar[sidebar_root_name],
        worker_amount = sidebar[sidebar_amount_label_name],
        worker_total = sidebar[sidebar_total_label_name],
        worker_total_required = sidebar[sidebar_total_required_label_name],
        employment_key = sidebar[sidebar_employed_key_label_name],
        employment = sidebar[sidebar_employed_label_name],
        priority = sidebar[sidebar_switch_name],
        network_id = sidebar[network_id_label_name]
    }
end

---@param entity LuaEntity
---@return ScriptObjectWithWorkers?
local function get_worker_object(entity)
    local unit_number = entity.unit_number
    if not unit_number then return end

    return compounds.get_compound(unit_number) or camps.get_camp(unit_number)
end

---@type table<DistributionPriority, SwitchState>
local priority_to_switch_state = {
    [priority_enum.Low] = "left",
    [priority_enum.Medium] = "none",
    [priority_enum.High] = "right"
}

---@type table<SwitchState, DistributionPriority>
local switch_state_to_priority = {
    ["left"] = priority_enum.Low,
    ["none"] = priority_enum.Medium,
    ["right"] = priority_enum.High,
}

---@param event EventData.on_gui_opened
local function on_gui_opened(event)
    local entity = event.entity
    if not entity then return end
  
    local player = game.get_player(event.player_index)
    if not player then
        error("No player")
    end

    local worker_object = get_worker_object(entity)
    if not worker_object then return end

    open_gui_entity[event.player_index] = entity

    local sidebar = create_worker_sidebar(player.gui.relative, entity)
    storage.gui_sidebar[player.index] = sidebar.root

    sidebar.worker_amount.caption = tostring(worker_object.assigned_workers) .. "/" .. tostring(worker_object.max_workers)
    local network_id = worker_object.path_network_id
    if network_id then
        local distribution = worker_distribution.get_distribution(network_id)
        if not distribution then error("No worker_distribution with id " .. network_id) end

        local total_workers = distribution:get_total_required().total
        local available_workers = worker_distribution.get_total_workers(network_id)
        local surplus_workers = total_workers - available_workers

        sidebar.network_id.caption = tostring(network_id)
        sidebar.worker_total.caption = tostring(worker_distribution.get_total_workers(network_id))
        sidebar.worker_total_required.caption = tostring(total_workers)

        if surplus_workers < 0 then
            sidebar.employment_key.caption = "Unemployed:"
            sidebar.employment.caption = tostring(-surplus_workers)
        else
            sidebar.employment_key.caption = "Labor Shortage:"
            sidebar.employment.caption = tostring(surplus_workers)
        end
    end

    if worker_object.worker_priority then
        sidebar.priority.switch_state = priority_to_switch_state[worker_object.worker_priority]
    else
        sidebar.priority.switch_state = "none"
    end
end

---@param event EventData.on_gui_closed
local function on_gui_closed(event)
    local player = game.get_player(event.player_index)

    if not player then return end
    
    local sidebar = storage.gui_sidebar[player.index]
    if not sidebar then return end

    sidebar.destroy()
    open_gui_entity[event.player_index] = nil
end

---@param event EventData.on_gui_switch_state_changed
local function on_gui_switch_state_changed(event)
    if event.element.name ~= sidebar_switch_name then return end
    local entity = open_gui_entity[event.player_index]
    if not entity then return end

    local worker_object = get_worker_object(entity)
    if not worker_object then return end

    worker_object:set_priority(switch_state_to_priority[event.element.switch_state])

    local network_id = worker_object.path_network_id
    if network_id then
        worker_distribution.recalculate(network_id)
    end
end

gui = {}

gui.on_init = function()
    storage.gui_sidebar = {}
end

gui.on_load = function()
end

gui.on_configuration_changed = function()
    game.print("config changed")
    storage.gui_sidebar = {}
end

gui.events = {
    [defines.events.on_gui_opened] = on_gui_opened,
    [defines.events.on_gui_closed] = on_gui_closed,
    [defines.events.on_gui_switch_state_changed] = on_gui_switch_state_changed
}

return gui