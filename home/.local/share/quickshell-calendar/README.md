# Desktop calendar integration

A local calendar adapter for the Quickshell clock/calendar widget. It supports
multiple providers behind one interface, stores its private cache under
`~/.local/state/quickshell-calendar`, and runs as the `quickshell-calendar.service`
`systemd --user` service.

## Providers

| Provider | Access | Notes |
| --- | --- | --- |
| `proton` | Read/write | Uses the local `proton-cal` CLI and `~/.config/proton-cal/session.json`. |
| `ics` | Read-only | One or more subscription URLs: a Google Calendar *secret address in iCal format*, a Proton Calendar share link, a CalDAV export, or any other ICS URL. |

Choose a provider with `~/.local/bin/calendar-connect` (also reached from the
calendar's **Connect a calendar…** button). An existing Proton sign-in is
detected automatically, so upgrading the adapter never forces a re-login.

Configuration lives in `~/.config/quickshell-calendar/config.toml` (0700/0600):

```toml
provider = "ics"

[[ics]]
name = "Google"
url = "https://calendar.google.com/calendar/ical/.../basic.ics"
```

`bridge.py configure <set-provider PROVIDER|add-ics NAME URL|clear-ics|clear>`
edits that file non-interactively.

## Using a subscription (Google, Proton share link, other)

1. In Google Calendar: *Settings → your calendar → Secret address in iCal format*.
   In Proton Calendar: create a sharing link for the calendar.
2. Run `calendar-connect`, choose **Add a calendar subscription**, and paste the URL.
3. Open the calendar and press **Sync**.

Subscriptions are read-only, so event creation stays in the source calendar.
Recurring events are expanded with `python-dateutil` when present and a built-in
fallback otherwise.

## Proton specifics

Built from cheeseandcereal/proton-cal commit 5ff2791 with GOMAXPROCS=2,
CGO_ENABLED=0 and GOFLAGS=-p=2. The x86-64 static binary is ~/.local/bin/proton-cal.
Source: ~/.local/src/proton-cal on the build machine. No Go runtime is needed.

Click the clock, then **Connect a calendar** → **Sign in to Proton**. Sign in in
the local terminal, including any CAPTCHA and TOTP requested by Proton. Account
credentials are excluded from ordinary portable-sync and its journals.

Select a date, then **+ Event**. Choose a calendar, time, and reminder, then Save.
All-day reminders use midnight in the configured calendar timezone. Sync manually
refreshes the visible month and upcoming reminders. The background service checks
cached device reminders every five seconds, even with the panel closed. Recurring
occurrences and effective calendar-default reminders come from proton-cal. Email
reminders stay with Proton. Notifications are deduplicated across restarts. Missed
reminders catch up for 15 minutes; reminders older than that are not flooded.

## Operations

- Service: `systemctl --user status quickshell-calendar.service`
- Restart: `systemctl --user restart quickshell-calendar.service`
- Connect/change provider: `~/.local/bin/calendar-connect`
- Private cache: `~/.local/state/quickshell-calendar` (0700; files 0600).
- Tests: `python3 ~/.local/share/quickshell-calendar/test_bridge.py`

The adapter does not log event content, passwords, or tokens. proton-cal is an
unofficial Proton API client; keep Proton mobile reminders enabled.

Manual sync policy: only the calendar's Sync button fetches events. Opening the
widget, changing months, starting the service, and idle time do not sync. Saving
an event writes it to Proton; press Sync afterward to refresh the local list and
schedule its reminders. Changes on other devices are unknown locally until the
next manual sync.
