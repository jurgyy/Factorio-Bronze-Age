local flib_gui = require("__flib__/gui-lite")

local compounds = require("script/worker-compounds")
local camps = require("script/camp")
local worker_distribution = require("script/worker-distribution")
local priority_enum = require("script/worker-priority")

local function should_monitor_entity(entity)
    return entity.name == "pottery-workshop"
end

---@class WorkerSidebarGui
---@field root LuaGuiElement
---@field worker_amount LuaGuiElement
---@field worker_total LuaGuiElement
---@field unemployed LuaGuiElement
---@field priority LuaGuiElement
---@field network_id LuaGuiElement

local sidebar_root_name = "sidebar-root"
local sidebar_amount_label_name = "sidebar-amount-label"
local sidebar_total_label_name = "sidebar-total-label"
local sidebar_unemployed_label_name = "sidebar-unemployed-label"
local sidebar_switch_name = "sidebar-priority-switch"
local network_id_label_name = "sidebar-network-label"

---@param parent LuaGuiElement
---@param entity LuaEntity
---@return WorkerSidebarGui sidebar
local function create_worker_sidebar(parent, entity)
    local sidebar = flib_gui.add(parent, {
        type = "frame",
        name = sidebar_root_name,
        caption = "Workers",
        direction = "vertical",
        anchor = {
            gui = defines.relative_gui_type.assembling_machine_gui,
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
                        {type="label", caption="Total Workers:", style="heading_3_label"},
                        {type="empty-widget", style="flib_horizontal_pusher"},
                        {type="label", style="label", caption="-", name=sidebar_total_label_name}
                    }
                },
                {
                    type="flow", direction="horizontal", style="ba_sidebar_row", children = {
                        {type="label", caption="Unemployed:", style="heading_3_label"},
                        {type="empty-widget", style="flib_horizontal_pusher"},
                        {type="label", style="label", caption="-", name=sidebar_unemployed_label_name}
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
        unemployed = sidebar[sidebar_unemployed_label_name],
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

---@param priority DistributionPriority
---@return SwitchState
local function priority_to_switch_state(priority)
    if priority == priority_enum.Medium then return "none" end
    if priority == priority_enum.High then return "right" end
    return "left"
end

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

    local sidebar = create_worker_sidebar(player.gui.relative, entity)
    global.gui_sidebar[player.index] = sidebar.root

    sidebar.worker_amount.caption = tostring(worker_object.assigned_workers) .. "/" .. tostring(worker_object.max_workers)
    if worker_object.path_network_id then
        sidebar.network_id.caption = tostring(worker_object.path_network_id)
        sidebar.worker_total.caption = tostring(worker_distribution.get_total_workers(worker_object.path_network_id))
        sidebar.unemployed.caption = tostring(worker_distribution.unemployed or 0)
    end

    if worker_object.worker_priority then
        sidebar.priority.switch_state = priority_to_switch_state(worker_object.worker_priority)
    else
        sidebar.priority.switch_state = "none"
    end
end

---@param event EventData.on_gui_closed
local function on_gui_closed(event)
    local player = game.get_player(event.player_index)

    if not player then return end
    
    local sidebar = global.gui_sidebar[player.index]
    if not sidebar then return end

    sidebar.destroy()
end

gui = {}

gui.on_init = function()
    global.gui_sidebar = {}
end

gui.on_load = function()
end

gui.on_configuration_changed = function()
    game.print("config changed")
    global.gui_sidebar = {}
end

gui.events = {
    [defines.events.on_gui_opened] = on_gui_opened,
    [defines.events.on_gui_closed] = on_gui_closed
}

return gui