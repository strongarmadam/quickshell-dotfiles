-- HyprExpo, built against the installed Hyprland headers.
hl.plugin.load("@HOME@/.local/lib/hyprland/hyprexpo-theme-bg.so")
hl.config({ plugin = { hyprexpo = {
    columns = 3,
    rows = 2,
    workspace_method = "first 1",
    dynamic_grid = 0,
    fill_gaps = 0,
    skip_empty = 0,
    max_workspace = 5,
    wallpaper_bg = 1,
    gaps_in = 16,
    gaps_out = 32,
    show_workspace_names = 1,
    drag_drop_enable = 0,
} } })
-- Keep the first five slots, growing through the highest workspace in use.
function open_workspace_overview()
    local last = 5
    local active = hl.get_active_workspace()
    for _, workspace in ipairs(hl.get_workspaces()) do
        if not workspace.special and (workspace.windows > 0 or (active and workspace.id == active.id)) then
            last = math.max(last, workspace.id)
        end
    end
    local columns = math.min(7, math.ceil(math.sqrt(last)))
    local rows = math.min(7, math.ceil(last / columns))
    hl.config({ plugin = { hyprexpo = {
        columns = columns,
        rows = rows,
        max_workspace = last,
    } } })
    hl.exec_scheduled_prop_refresh_immediately()
    hl.plugin.hyprexpo.expo("toggle")
end
hl.bind("SUPER + W", open_workspace_overview,
    { description = "Workspace overview" })
hl.define_submap("hyprexpo", function()
    for _, direction in ipairs({ "left", "right", "up", "down" }) do
        hl.bind(direction, function() hl.plugin.hyprexpo.kb_focus(direction) end)
    end
    hl.bind("RETURN", function() hl.plugin.hyprexpo.kb_confirm() end)
    hl.bind("ESCAPE", function() hl.plugin.hyprexpo.expo("cancel") end)
    hl.bind("SUPER + W", function() hl.plugin.hyprexpo.expo("cancel") end)
end)
