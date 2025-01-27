return {
    {
        type = "recipe",
        name = "wooden-chest",
        ingredients = {{type = "item", name = "wood", amount = 2}},
        results = {{type = "item", name = "wooden-chest", amount = 1}}
    },
    {
        type = "recipe",
        name = "iron-chest",
        enabled = false,
        ingredients = {{type = "item", name = "iron-plate", amount = 8}},
        results = {{type = "item", name = "iron-chest", amount = 1}}
    },
    {
        type = "recipe",
        name = "transport-belt",
        ingredients =
        {
        --   {"iron-plate", 1},
        --   {"iron-gear-wheel", 1}
            {type = "item", name = "wood", amount = 1},
            {type = "item", "clay-disk", amount = 6}
        },
        results = {{type = "item", name = "transport-belt"}},
        result_count = 2
    },
    {
        type = "recipe",
        name = "fast-transport-belt",
        enabled = false,
        ingredients =
        {
            {type = "item", name = "iron-gear-wheel", amount = 5},
            {type = "item", name = "transport-belt", amount = 1}
        },
        results = {{type = "item", name = "fast-transport-belt"}}
    },
    {
        type = "recipe",
        name = "express-transport-belt",
        category = "crafting-with-fluid",
        enabled = false,
        ingredients =
        {
            {type = "item", name = "iron-gear-wheel", amount = 10},
            {type = "item", name = "fast-transport-belt", amount = 1},
            {type = "fluid", name = "lubricant", amount = 20}
        },
        results = {{type = "item", name = "express-transport-belt"}}
    },
    {
        type = "recipe",
        name = "underground-belt",
        enabled = false,
        energy_required = 1,
        ingredients =
        {
          {type = "item", name = "iron-plate", amount = 10},
          {type = "item", name = "transport-belt", amount = 5}
        },
        result_count = 2,
        results = {{type = "item", name = "underground-belt"}}
    },
    {
        type = "recipe",
        name = "fast-underground-belt",
        energy_required = 2,
        enabled = false,
        ingredients =
        {
          {type = "item", name = "iron-gear-wheel", amount = 40},
          {type = "item", name = "underground-belt", amount = 2}
        },
        result_count = 2,
        results = {{type = "item", name = "fast-underground-belt"}}
    },
    {
        type = "recipe",
        name = "express-underground-belt",
        energy_required = 2,
        category = "crafting-with-fluid",
        enabled = false,
        ingredients =
        {
          {type = "item", name = "iron-gear-wheel", amount = 80},
          {type = "item", name = "fast-underground-belt", amount = 2},
          {type = "fluid", name ="lubricant", amount = 40}
        },
        result_count = 2,
        results = {{type = "item", name = "express-underground-belt"}}
    },
    {
        type = "recipe",
        name = "splitter",
        enabled = false,
        energy_required = 1,
        ingredients =
        {
          {type = "item", name = "electronic-circuit", amount = 5},
          {type = "item", name = "iron-plate", amount = 5},
          {type = "item", name = "transport-belt", amount = 4}
        },
        results = {{type = "item", name = "splitter"}}
    },
    {
        type = "recipe",
        name = "fast-splitter",
        enabled = false,
        energy_required = 2,
        ingredients =
        {
          {type = "item", name = "splitter", amount = 1},
          {type = "item", name = "iron-gear-wheel", amount = 10},
          {type = "item", name = "electronic-circuit", amount = 10}
        },
        results = {{type = "item", name = "fast-splitter"}}
    },
    {
        type = "recipe",
        name = "express-splitter",
        category = "crafting-with-fluid",
        enabled = false,
        energy_required = 2,
        ingredients =
        {
          {type = "item", name = "fast-splitter", amount = 1},
          {type = "item", name = "iron-gear-wheel", amount = 10},
          {type = "item", name = "advanced-circuit", amount = 10},
          {type = "fluid", name = "lubricant", amount = 80}
        },
        results = {{type = "item", name = "express-splitter"}}
    },
    {
        type = "recipe",
        name = "inserter",
        ingredients =
        {
        --   {"electronic-circuit", 1},
        --   {"iron-gear-wheel", 1},
        --   {"iron-plate", 1},
          {type = "item", name = "clay-disk", amount = 3},
          {type = "item", name = "stone", amount = 1},
          {type = "item", name = "wood", amount = 2}
        },
        results = {{type = "item", name = "inserter"}}
    },
    {
        type = "recipe",
        name = "long-handed-inserter",
        enabled = false,
        ingredients =
        {
          {type = "item", name = "iron-gear-wheel", amount = 1},
          {type = "item", name = "iron-plate", amount = 1},
          {type = "item", name = "inserter", amount = 1}
        },
        results = {{type = "item", name = "long-handed-inserter"}}
    },
    {
        type = "recipe",
        name = "fast-inserter",
        enabled = false,
        ingredients =
        {
          {type = "item", name = "electronic-circuit", amount = 2},
          {type = "item", name = "iron-plate", amount = 2},
          {type = "item", name = "inserter", amount = 1}
        },
        results = {{type = "item", name = "fast-inserter"}}
    },
    {
        type = "recipe",
        name = "filter-inserter",
        enabled = false,
        ingredients =
        {
          {type = "item", name = "fast-inserter", amount = 1},
          {type = "item", name = "electronic-circuit", amount = 4}
        },
        results = {{type = "item", name = "filter-inserter"}}
    },
    {
        type = "recipe",
        name = "stack-inserter",
        enabled = false,
        ingredients =
        {
          {type = "item", name = "iron-gear-wheel", amount = 15},
          {type = "item", name = "electronic-circuit", amount = 15},
          {type = "item", name = "advanced-circuit", amount = 1},
          {type = "item", name = "fast-inserter", amount = 1}
        },
        results = {{type = "item", name = "stack-inserter"}}
    },
    {
        type = "recipe",
        name = "stack-filter-inserter",
        enabled = false,
        ingredients =
        {
          {type = "item", name = "stack-inserter", amount = 1},
          {type = "item", name = "electronic-circuit", amount = 5}
        },
        results = {{type = "item", name = "stack-filter-inserter"}}
    },
    {
        type = "recipe",
        name = "small-lamp",
        enabled = false,
        ingredients =
        {
          {type = "item", name = "electronic-circuit", amount = 1},
          {type = "item", name = "copper-cable", amount = 3},
          {type = "item", name = "iron-plate", amount = 1}
        },
        results = {{type = "item", name = "small-lamp"}}
    },
    {
        type = "recipe",
        name = "red-wire",
        enabled = false,
        ingredients =
        {
          {type = "item", name = "electronic-circuit", amount = 1},
          {type = "item", name = "copper-cable", amount = 1}
        },
        results = {{type = "item", name = "red-wire"}}
    },
    {
        type = "recipe",
        name = "green-wire",
        enabled = false,
        ingredients =
        {
          {type = "item", name = "electronic-circuit", amount = 1},
          {type = "item", name = "copper-cable", amount = 1}
        },
        results = {{type = "item", name = "green-wire"}}
    },
    {
        type = "recipe",
        name = "arithmetic-combinator",
        enabled = false,
        ingredients =
        {
          {type = "item", name = "copper-cable", amount = 5},
          {type = "item", name = "electronic-circuit", amount = 5}
        },
        results = {{type = "item", name = "arithmetic-combinator"}}
    },
    {
        type = "recipe",
        name = "decider-combinator",
        enabled = false,
        ingredients =
        {
          {type = "item", name = "copper-cable", amount = 5},
          {type = "item", name = "electronic-circuit", amount = 5}
        },
        results = {{type = "item", name = "decider-combinator"}}
    },
    {
        type = "recipe",
        name = "constant-combinator",
        enabled = false,
        ingredients =
        {
          {type = "item", name = "copper-cable", amount = 5},
          {type = "item", name = "electronic-circuit", amount = 2}
        },
        results = {{type = "item", name = "constant-combinator"}}
    },
    {
        type = "recipe",
        name = "power-switch",
        enabled = false,
        energy_required = 2,
        ingredients =
        {
          {type = "item", name = "iron-plate", amount = 5},
          {type = "item", name = "copper-cable", amount = 5},
          {type = "item", name = "electronic-circuit", amount = 2}
        },
        results = {{type = "item", name = "power-switch"}}
    },
    {
        type = "recipe",
        name = "programmable-speaker",
        enabled = false,
        energy_required = 2,
        ingredients =
        {
          {type = "item", name = "iron-plate", amount = 3},
          {type = "item", name = "iron-stick", amount = 4},
          {type = "item", name = "copper-cable", amount = 5},
          {type = "item", name = "electronic-circuit", amount = 4}
        },
        results = {{type = "item", name = "programmable-speaker"}}
    }
}