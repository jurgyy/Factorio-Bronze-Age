return {
    {
        type = "recipe",
        name = "wooden-chest",
        ingredients = {{"wood", 2}},
        result = "wooden-chest"
    },
    {
        type = "recipe",
        name = "iron-chest",
        enabled = true,
        ingredients = {{"iron-plate", 8}},
        result = "iron-chest"
    },
    {
        type = "recipe",
        name = "transport-belt",
        ingredients =
        {
          {"iron-plate", 1},
          {"iron-gear-wheel", 1}
        },
        result = "transport-belt",
        result_count = 2
    },
    {
        type = "recipe",
        name = "fast-transport-belt",
        enabled = true, --enabled = false,
        ingredients =
        {
          {"iron-gear-wheel", 5},
          {"transport-belt", 1}
        },
        result = "fast-transport-belt"
    },
    {
        type = "recipe",
        name = "express-transport-belt",
        category = "crafting-with-fluid",
        ingredients =
        {
        {"iron-gear-wheel", 10},
        {"fast-transport-belt", 1},
        {type="fluid", name="lubricant", amount=20}
        },
        result = "express-transport-belt"
    },
    {
        type = "recipe",
        name = "underground-belt",
        enabled = true, --enabled = false,
        energy_required = 1,
        ingredients =
        {
          {"iron-plate", 10},
          {"transport-belt", 5}
        },
        result_count = 2,
        result = "underground-belt"
    },
    {
        type = "recipe",
        name = "fast-underground-belt",
        energy_required = 2,
        enabled = true, --enabled = false,
        ingredients =
        {
          {"iron-gear-wheel", 40},
          {"underground-belt", 2}
        },
        result_count = 2,
        result = "fast-underground-belt"
    },
    {
        type = "recipe",
        name = "express-underground-belt",
        energy_required = 2,
        category = "crafting-with-fluid",
        enabled = true, --enabled = false,
        ingredients =
        {
          {"iron-gear-wheel", 80},
          {"fast-underground-belt", 2},
          {type="fluid", name="lubricant", amount=40}
        },
        result_count = 2,
        result = "express-underground-belt"
    },
    {
        type = "recipe",
        name = "splitter",
        enabled = true, --enabled = false,
        energy_required = 1,
        ingredients =
        {
          {"electronic-circuit", 5},
          {"iron-plate", 5},
          {"transport-belt", 4}
        },
        result = "splitter"
    },
    {
        type = "recipe",
        name = "fast-splitter",
        enabled = true, --enabled = false,
        energy_required = 2,
        ingredients =
        {
          {"splitter", 1},
          {"iron-gear-wheel", 10},
          {"electronic-circuit", 10}
        },
        result = "fast-splitter"
    },
    {
        type = "recipe",
        name = "express-splitter",
        category = "crafting-with-fluid",
        enabled = true, --enabled = false,
        energy_required = 2,
        ingredients =
        {
          {"fast-splitter", 1},
          {"iron-gear-wheel", 10},
          {"advanced-circuit", 10},
          {type="fluid", name="lubricant", amount=80}
        },
        result = "express-splitter"
    },
    {
        type = "recipe",
        name = "inserter",
        ingredients =
        {
          {"electronic-circuit", 1},
          {"iron-gear-wheel", 1},
          {"iron-plate", 1}
        },
        result = "inserter"
    },
    {
        type = "recipe",
        name = "long-handed-inserter",
        enabled = true, --enabled = false,
        ingredients =
        {
          {"iron-gear-wheel", 1},
          {"iron-plate", 1},
          {"inserter", 1}
        },
        result = "long-handed-inserter"
    },
    {
        type = "recipe",
        name = "fast-inserter",
        enabled = true, --enabled = false,
        ingredients =
        {
          {"electronic-circuit", 2},
          {"iron-plate", 2},
          {"inserter", 1}
        },
        result = "fast-inserter"
    },
    {
        type = "recipe",
        name = "filter-inserter",
        enabled = true, --enabled = false,
        ingredients =
        {
          {"fast-inserter", 1},
          {"electronic-circuit", 4}
        },
        result = "filter-inserter"
    },
    {
        type = "recipe",
        name = "stack-inserter",
        enabled = true, --enabled = false,
        ingredients =
        {
          {"iron-gear-wheel", 15},
          {"electronic-circuit", 15},
          {"advanced-circuit", 1},
          {"fast-inserter", 1}
        },
        result = "stack-inserter"
    },
    {
        type = "recipe",
        name = "stack-filter-inserter",
        enabled = true, --enabled = false,
        ingredients =
        {
          {"stack-inserter", 1},
          {"electronic-circuit", 5}
        },
        result = "stack-filter-inserter"
    },
    {
        type = "recipe",
        name = "small-lamp",
        enabled = true, --enabled = false,
        ingredients =
        {
          {"electronic-circuit", 1},
          {"copper-cable", 3},
          {"iron-plate", 1}
        },
        result = "small-lamp"
    },
    {
        type = "recipe",
        name = "red-wire",
        enabled = true, --enabled = false,
        ingredients =
        {
          {"electronic-circuit", 1},
          {"copper-cable", 1}
        },
        result = "red-wire"
    },
    {
        type = "recipe",
        name = "green-wire",
        enabled = true, --enabled = false,
        ingredients =
        {
          {"electronic-circuit", 1},
          {"copper-cable", 1}
        },
        result = "green-wire"
    },
    {
        type = "recipe",
        name = "arithmetic-combinator",
        enabled = true, --enabled = false,
        ingredients =
        {
          {"copper-cable", 5},
          {"electronic-circuit", 5}
        },
        result = "arithmetic-combinator"
    },
    {
        type = "recipe",
        name = "decider-combinator",
        enabled = true, --enabled = false,
        ingredients =
        {
          {"copper-cable", 5},
          {"electronic-circuit", 5}
        },
        result = "decider-combinator"
    },
    {
        type = "recipe",
        name = "constant-combinator",
        enabled = true, --enabled = false,
        ingredients =
        {
          {"copper-cable", 5},
          {"electronic-circuit", 2}
        },
        result = "constant-combinator"
    },
    {
        type = "recipe",
        name = "power-switch",
        enabled = true, --enabled = false,
        energy_required = 2,
        ingredients =
        {
          {"iron-plate", 5},
          {"copper-cable", 5},
          {"electronic-circuit", 2}
        },
        result = "power-switch"
    },
    {
        type = "recipe",
        name = "programmable-speaker",
        enabled = true, --enabled = false,
        energy_required = 2,
        ingredients =
        {
          {"iron-plate", 3},
          {"iron-stick", 4},
          {"copper-cable", 5},
          {"electronic-circuit", 4}
        },
        result = "programmable-speaker"
    }
}