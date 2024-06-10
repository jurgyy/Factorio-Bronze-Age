local data_util = require("__bronze-age__/data/data-util")


data:extend{{
    type = "technology",
    name = "pottery",
    icon_size = 64, icon_mipmaps = 1,
    icon = data_util.tech_icons_root .. "pottery.png",
    effects =
    {
      {
        type = "unlock-recipe",
        recipe = "potter"
      },
      {
        type = "unlock-recipe",
        recipe = "pottery"
      },
      {
        type = "unlock-recipe",
        recipe = "bricks"
      }
    },
    unit =
    {
      count = 10,
      ingredients = {{"hephaestus-blessing", 1}},
      time = 15
    },
    order = "a"
},{
    type = "technology",
    name = "masonry",
    icon_size = 64, icon_mipmaps = 1,
    icon = data_util.tech_icons_root .. "masonry.png",
    effects =
    {
      {
        type = "unlock-recipe",
        recipe = "masonry"
      }
    },
    prerequisites = {"pottery"},
    unit =
    {
      count = 10,
      ingredients = {{"hephaestus-blessing", 1}},
      time = 15
    },
    order = "a"
},{
    type = "technology",
    name = "smithing",
    icon_size = 64, icon_mipmaps = 1,
    icon = data_util.tech_icons_root .. "smithing.png",
    effects =
    {
      {
        type = "unlock-recipe",
        recipe = "forge"
      },
      {
        type = "unlock-recipe",
        recipe = "copper-smith"
      },
      {
        type = "unlock-recipe",
        recipe = "copper-tools"
      }
    },
    prerequisites = {"masonry"},
    unit =
    {
      count = 10,
      ingredients = {{"hephaestus-blessing", 1}},
      time = 15
    },
    order = "a"
},{
    type = "technology",
    name = "mining",
    icon_size = 64, icon_mipmaps = 1,
    icon = data_util.tech_icons_root .. "mining.png",
    effects =
    {
      {
        type = "unlock-recipe",
        recipe = "mining-camp"
      },
    },
    prerequisites = {"smithing"},
    unit =
    {
      count = 10,
      ingredients = {{"hephaestus-blessing", 1}},
      time = 15
    },
    order = "a"
},
}