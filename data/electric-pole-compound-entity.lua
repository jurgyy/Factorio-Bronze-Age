local pole = table.deepcopy(data.raw["electric-pole"]["medium-electric-pole"])
pole.name = "electric-pole-compound"
pole.localised_name = nil
pole.localised_description = nil
pole.supply_area_distance = 2.5 -- Supplies only the tile it's standing on
pole.maximum_wire_distance = 1
pole.allow_copy_paste = false
pole.selectable_in_game  = true
pole.draw_copper_wires = false
pole.flags = {
    "not-rotatable", "placeable-neutral", "not-repairable", "not-on-map", "not-deconstructable",
    "not-blueprintable", "hidden", "not-selectable-in-game", "not-upgradable", "not-in-kill-statistics",
    "not-in-made-in"
}
pole.collision_mask = {}

for _, layer in pairs(pole.pictures.layers) do
    layer.tint = {r = 0, g = 0, b = 0, a = 0.2}
    layer.hr_version.tint = {r = 0, g = 0, b = 0, a = 0.2}
end

return pole