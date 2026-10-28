# Share the curated repository

Publish this directory, not your live home directory or dotfiles backups.
`home/` is an explicit export allowlist. Re-run `python3 scripts/check.py` after
changes. Pattern scans supplement manual review; they are not a guarantee that
arbitrary future files contain no secrets.

To publish to an empty GitHub repository you create:

```sh
git init -b main
git add .
git diff --cached --stat
git commit -m "Add themed Quickshell desktop and setup wizard"
git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPOSITORY.git
git push -u origin main
```

Use GitHub's normal sign-in outside the repository. Do not put a token in a URL,
script, or example. Git identity is your choice; use a GitHub noreply email if you
want to keep your personal email out of commit history. The local export has no
remote and no copied history from the working machine.

Before posting a screenshot, hide notifications, calendar details, clipboard
history, terminal prompts/commands, browser tabs, connected device names, Wi-Fi
names, and personal filenames. The included wallpaper images are not screenshots.
Take screenshots of a clean session; do not upload an unreviewed desktop capture.

Suggested post title:

> [Hyprland] Eight themes, retractable Quickshell widgets, and a theme creator

Suggested post body (replace the repository placeholder):

> My Hyprland + Quickshell setup now has eight coordinated themes, movable system
> monitors, a retractable status bar, Bluetooth/network popups, and a GUI theme
> creator. The public dotfiles include a setup wizard for your own browser,
> terminal, file manager, launch shortcuts, keyboard layout, and display scale.
>
> Dotfiles: **YOUR_REPOSITORY_URL**
>
> Built on Arch with Hyprland 0.56.2 / Quickshell 0.3.2. Uses Lua compositor
> configuration. Apps and accounts are not bundled; the calendar is standalone.
> Overview plugin source is included as a separate opt-in build.

Check the chosen community's current posting rules before submitting. Nothing
in this export automatically publishes a repository or posts to a community.
