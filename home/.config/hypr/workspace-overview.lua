-- Standalone Quickshell overview: public IPC and Wayland window capture.
-- No native plugin is loaded into the compositor.
hl.bind("SUPER + W", hl.dsp.exec_cmd("@HOME@/.local/bin/workspace-overview"),
    { description = "Workspace overview" })
hl.layer_rule({
    name = "workspace-overview-overlay",
    match = { namespace = "^quickshell-overview$" },
    no_anim = true,
})
