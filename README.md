# Sandboxed Obsidian (macOS)

Confines the [Obsidian](https://obsidian.md) desktop app to a single vault
directory using macOS's built-in `sandbox-exec` (Seatbelt), so it can't read
or write anywhere else on disk beyond what it needs to run.

## Usage

```bash
chmod +x run-obsidian-sandboxed.sh
./run-obsidian-sandboxed.sh ~/Documents/MyVault
```

That's it — the script resolves your vault to an absolute path and feeds it,
your home directory, and the app location into the profile as sandbox
parameters. No editing of the `.sb` file required for the common case.

Optional overrides:

```bash
APP_PATH=/Applications/Obsidian.app ./run-obsidian-sandboxed.sh ~/Documents/MyVault
```

You can make a clickable "app" via Automator's "Run Shell Script" automation:

```bash
nohup ~/obsidian-sb/run-obsidian-sandboxed.sh ~/Documents/Obsidian\ Vault > /dev/null 2>&1 < /dev/null &
disown
```

## What this does and doesn't protect against

**Confines:** filesystem reads/writes to your vault directory, its own app
data (prefs, cache), and the small set of system paths/services Electron
needs to boot and render a window.

**Does not confine:** outbound network access — it's unrestricted
(`network-outbound` is wide open). Obsidian's own update checker,
community plugins, and any sync services you use all need this, and
scoping it down to specific hosts would need per-plugin knowledge this
profile doesn't have. If you want that tighter, see the "Tightening
further" section below.

## Why `--no-sandbox` is in the launcher

Electron/Chromium has its own internal sandbox layer for its
renderer/GPU subprocesses. A process that's itself already sandboxed by
an *external* `sandbox-exec` profile can't successfully apply a *further*
nested Seatbelt profile to its own children — the attempt fails, and
Chromium treats a failed GPU process as fatal. `--no-sandbox` disables
Chromium's internal sandbox; the outer `sandbox-exec` profile is doing
the actual isolation instead, so this isn't a meaningful loosening in
this setup.

## Requirements / caveats

- **macOS only.** Uses `sandbox-exec`, an Apple-private, undocumented,
  and technically deprecated API (still functional as of macOS 26, but
  Apple has given no guarantee it stays that way across OS versions).
- Tested against Obsidian's Electron/Chromium internals as of mid-2026.
  Electron upgrades can introduce new mach services or file paths the
  app needs; if you hit a blank window, crash, or high CPU after an
  Obsidian update, check `log stream --style syslog --predicate
  'sender == "Sandbox"'` while reproducing — that's how every rule in
  this profile was derived.
- The bundle identifier `md.obsidian` and a few Electron-internal
  service name patterns are hardcoded (they're constant across
  installs, unlike your home directory or vault path).

## Tightening further

If you want to scope `network-outbound` down instead of leaving it open,
you'll need to enumerate the hosts your specific plugins/sync setup
actually talk to and add `(allow network-outbound (remote ip
"host:port"))`-style rules — left out here since that's genuinely
per-user, unlike everything else in this profile.

## Debugging a fresh denial

```bash
log stream --style syslog --predicate 'sender == "Sandbox"' --info
```

Run that in one terminal, reproduce the issue in another, and look for
`deny(1)` lines naming the process and operation. Most fixes are a
one-line `(allow ...)` addition matching what's denied.
