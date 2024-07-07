local inserters = data.raw["inserter"]

data.raw["recipe"]["burner-inserter"] = nil

local inserter = inserters["inserter"]
inserter.energy_per_movement = "0J"
inserter.energy_per_rotation = tostring(1 / (inserter.rotation_speed * 60)) .. "J"
inserter.energy_source.drain = nil
-- inserter.pickup_position = {0, -2}
-- inserter.insert_position = {0, 2.2}
-- inserter.hand_size = 1.5