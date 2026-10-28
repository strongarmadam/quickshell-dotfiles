-- Space Green
-- Sleek dark-space visual theme

hl.config({
    general = {
        gaps_in = 6,
        gaps_out = 18,

        border_size = 2,

    col = {
        active_border = {
            colors = {
                "rgba(315c46ff)",
                "rgba(8fbf72ff)",
                "rgba(f3c969ff)"
            },
            angle = 135
        },
        inactive_border = "rgba(1b3025cc)",
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

-- Space Green animation curves

hl.curve("spaceEase", {
    type = "bezier",
    points = {
        {0.16, 1},
        {0.3, 1}
    }
})

hl.curve("spaceSmooth", {
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
    bezier = "spaceEase"
})

hl.animation({
    leaf = "windows",
    enabled = true,
    speed = 5,
    bezier = "spaceEase"
})

hl.animation({
    leaf = "windowsIn",
    enabled = true,
    speed = 4,
    bezier = "spaceEase",
    style = "popin 90%"
})

hl.animation({
    leaf = "windowsOut",
    enabled = true,
    speed = 4,
    bezier = "spaceSmooth",
    style = "popin 90%"
})

hl.animation({
    leaf = "fade",
    enabled = true,
    speed = 4,
    bezier = "spaceSmooth"
})

hl.animation({
    leaf = "workspaces",
    enabled = true,
    speed = 4,
    bezier = "spaceSmooth",
    style = "slide"
})









