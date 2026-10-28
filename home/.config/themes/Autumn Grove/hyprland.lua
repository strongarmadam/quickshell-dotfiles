-- Autumn Grove
-- Warm dark forest theme with soft khaki accents

hl.config({
    general = {
        gaps_in = 6,
        gaps_out = 18,

        border_size = 1,

        col = {
            active_border = {
                colors = {
                    "rgba(8b795dcc)",
                    "rgba(c59b62cc)"
                },
                angle = 135
            },

            inactive_border = "rgba(655743cc)",
        },

        resize_on_border = false,
        allow_tearing = false,
        layout = "dwindle",
    },

    decoration = {
        rounding = 18,
        rounding_power = 2,

        active_opacity = 0.96,
        inactive_opacity = 0.90,

        shadow = {
            enabled = true,
            range = 18,
            render_power = 3,
            color = "rgba(00000066)",
        },

        blur = {
            enabled = true,
            size = 6,
            passes = 3,
            vibrancy = 0.12,
            new_optimizations = true,
        },
    },

    animations = {
        enabled = true,
    },
})

hl.curve("autumnEase", {
    type = "bezier",
    points = {
        {0.16, 1},
        {0.3, 1}
    }
})

hl.curve("autumnSmooth", {
    type = "bezier",
    points = {
        {0.65, 0},
        {0.35, 1}
    }
})

hl.animation({
    leaf = "global",
    enabled = true,
    speed = 8,
    bezier = "autumnEase"
})

hl.animation({
    leaf = "windows",
    enabled = true,
    speed = 5,
    bezier = "autumnEase"
})

hl.animation({
    leaf = "windowsIn",
    enabled = true,
    speed = 4,
    bezier = "autumnEase",
    style = "popin 90%"
})

hl.animation({
    leaf = "windowsOut",
    enabled = true,
    speed = 4,
    bezier = "autumnSmooth",
    style = "popin 90%"
})

hl.animation({
    leaf = "fade",
    enabled = true,
    speed = 4,
    bezier = "autumnSmooth"
})

hl.animation({
    leaf = "workspaces",
    enabled = true,
    speed = 4,
    bezier = "autumnSmooth",
    style = "slide"
})








