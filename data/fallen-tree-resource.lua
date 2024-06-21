local function resource(resource_parameters)
    if coverage == nil then coverage = 0.02 end
  
    return
    {
      type = "resource",
      name = resource_parameters.name,
      icon = "__base__/graphics/icons/dead-grey-trunk.png",
      icon_size = 64,
      icon_mipmaps = 4,
      flags = {"placeable-neutral"},
      order="a-b-"..resource_parameters.order,
      tree_removal_probability = 0.8,
      tree_removal_max_distance = 32 * 32,
      minable =
      {
        mining_particle = "wooden-particle",
        mining_time = resource_parameters.mining_time,
        result = "wood"
      },
      walking_sound = resource_parameters.walking_sound,
      collision_box = {{-0.45, -0.45}, {0.45, 0.45}},
      selection_box = {{-0.5, -0.5}, {0.5, 0.5}},
      stage_counts = {1},
      stages =
      {
        sheet =
        {
          filename = "__bronze-age__/graphics/fallen-tree-resource/dead-dry-hairy-tree-00.png",
          priority = "extra-high",
          --size = 64,
          width = 195,
          height = 95,
          frame_count = 1,
          variation_count = 1,
          hr_version =
          {
            filename = "__bronze-age__/graphics/fallen-tree-resource/hr-dead-dry-hairy-tree-00.png",
            priority = "extra-high",
            --size = 128,
            width = 388,
            height = 189,
            frame_count = 1,
            variation_count = 1,
            scale = 0.5
          }
        }
      },
      map_color = resource_parameters.map_color,
      mining_visualisation_tint = resource_parameters.mining_visualisation_tint
    }
end

return resource({
    name = "ba-fallen-tree-resource",
    order = "z-z-z-z",
    map_color = {130, 70, 5},
    mining_time = 1,
    walking_sound = nil,
})