# Network connections

Super+Shift+N toggles the themed NetworkManager popup. Escape and clicking outside
close it. Wi-Fi shows nearby access points, security, signal and connection status;
Scan requests a rescan. Adapters includes Ethernet and Wi-Fi. Saved / VPN lists
NetworkManager profiles with connect/disconnect controls. Wi-Fi can be turned on
off when a wireless adapter is present and not hardware blocked.

Connect opens nmcli --ask in a local terminal for progress and any needed password.
Advanced opens nmtui for hidden networks and editing profiles, IP and DNS settings.
NetworkManager and its policy agent own authorization and credential storage; the
widget does not read passwords or transfer connection profiles between devices.
Some VPN/enterprise configurations need an additional NetworkManager plugin/editor.
Status refreshes every five seconds only while this popup is open; no new daemon.
Dependencies: NetworkManager (nmcli/nmtui), your selected terminal, Quickshell, existing theme helper.
