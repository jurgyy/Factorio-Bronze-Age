local eei = table.deepcopy(data.raw["electric-energy-interface"]["electric-energy-interface"])
eei.name = "compound-eei"
eei.localised_name = nil
eei.localised_description = nil
eei.gui_mode = "none"
eei.allow_copy_paste = false
eei.selectable_in_game  = true
eei.flags = {
    "not-rotatable", "placeable-neutral", "not-repairable", "not-on-map", "not-deconstructable",
    "not-blueprintable", "hidden", "not-selectable-in-game", "not-upgradable", "not-in-kill-statistics",
    "not-in-made-in"
}
eei.collision_mask = {}
eei.tile_height = 3
eei.tile_height = 5

eei.energy_production = "0W"
eei.energy_usage = "0W"
eei.energy_source = {
    type = "electric",
    buffer_capacity = "1J",
    usage_priority = "primary-output",
    input_flow_limit = "1PW",
    output_flow_limit = "1PW"
}

for _, layer in pairs(eei.picture.layers) do
    layer.tint = {r = 0, g = 0, b = 0, a = 0.2}
    layer.hr_version.tint = {r = 0, g = 0, b = 0, a = 0.2}
end

return eei