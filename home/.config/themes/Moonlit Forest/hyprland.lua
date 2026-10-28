-- Moonlit Forest
-- Classic sharp-edged Hyprland styling

hl.config({
    general = {
        gaps_in = 5,
        gaps_out = 20,

        border_size = 2,

        col = {
            active_border = {
                colors = {
                    "rgba(3aa9d2ee)",
                    "rgba(155779ee)"
                },
                angle = 45
            },

            inactive_border = "rgba(123d55cc)",
        },

        resize_on_border = false,
        allow_tearing = false,
        layout = "dwindle",
    },

    decoration = {
        rounding = 4,
        rounding_power = 2,

        active_opacity = 1.0,
        inactive_opacity = 1.0,

        shadow = {
            enabled = false,
            range = 4,
            render_power = 3,
            color = 0xee1a1a1a,
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








hl.layer_rule({
    match = {
        namespace = "quickshell",
    },
    blur = true,
    ignore_alpha = 0.30,
})


