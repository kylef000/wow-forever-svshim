# !!SVShim: keep your addon settings in the WoW Forever beta

[![VirusTotal scan](https://img.shields.io/badge/VirusTotal-scanned%20on%20release-3178C6?logo=virustotal&logoColor=white)](https://github.com/kylef000/wow-forever-svshim/releases/latest)

> **Fixed as of 2026-09-25.** Blizzard has fixed the underlying bug — the beta client loads SavedVariables normally again. This addon is no longer needed. It will still tell you so itself in chat (see [After Blizzard fixes the bug](#after-blizzard-fixes-the-bug)); once you see that message every login, close `Start-SVShim.cmd` and delete the `!!SVShim` folder. This repo is archived and kept only for anyone still on an older client build.

The WoW Forever (1.60.x) beta client **saves** addon settings when you `/reload` or log out, but it **never loads them** again. Every login, your addons start from their defaults, and the next save overwrites your settings with those defaults.

!!SVShim works around this. A small script copies your saved settings into the addon folder as code. The client still loads addon code, so your settings come back.

> This is a workaround for a beta bug. When Blizzard fixes it, the shim notices and tells you in chat that it can be removed. See [After Blizzard fixes the bug](#after-blizzard-fixes-the-bug).

## What you need

- Windows. The script uses PowerShell, which comes with Windows.
- The WoW Forever beta, installed in the `_classic_beta_` folder.

## Install

1. Go to [**Releases**](https://github.com/kylef000/wow-forever-svshim/releases/latest) and download **`SVShim-v<version>.zip`**. Don't use the green **Code → Download ZIP** button, because that folder would need renaming.
2. Extract it into your AddOns folder, for example:
   ```
   C:\Program Files (x86)\World of Warcraft\_classic_beta_\Interface\AddOns
   ```
   The ZIP already contains a folder named `!!SVShim`. The `!!` makes it load before your other addons.

If you use git, `git clone https://github.com/kylef000/wow-forever-svshim.git "!!SVShim"` inside `AddOns` works too.

The folder should look like this:

```
AddOns\!!SVShim\
    !!SVShim.toc
    Start-SVShim.cmd
    tools\sync.ps1
    ...
```

## Use it

**Every time you play:**

1. Double-click **`Start-SVShim.cmd`** in the `!!SVShim` folder. A window opens and says `Watching ...`. **Leave it open** while you play.
2. Play as normal. Each time the game saves (`/reload`, logout or exit), the window prints a line. That means your settings were copied.

On login you'll see a line like this in chat. The numbers depend on which addons you have enabled:

```
SVShim restored 13 account and 7 character settings files.
```

**First time only:** set your addons up the way you like them, then `/reload` once. From then on they stick.

> **Windows says "Windows protected your PC"?** That's normal for scripts downloaded from the internet. Click **More info → Run anyway**. You can read [`tools/sync.ps1`](tools/sync.ps1) first; it only reads your `WTF` folder and writes inside `!!SVShim`.

### If you forget to run it

Nothing breaks. You get back the settings from the last time the script was running, and anything you changed since then is lost.

### More than one Battle.net account

The script uses whichever account folder under `WTF\Account` was saved most recently. To choose a specific one, run:

```
powershell -ExecutionPolicy Bypass -File tools\sync.ps1 -Watch -Account YOURACCOUNT#1
```

## How it works

- The client writes each addon's settings to `WTF\Account\<account>\SavedVariables\<Addon>.lua`. Per-character settings go to `WTF\Account\<account>\<realm>\<character>\SavedVariables\`. Those files are valid Lua, for example `LeaPlusDB = { ... }`.
- [`tools/sync.ps1`](tools/sync.ps1) watches those folders. After each save it copies every addon's file into `!!SVShim\Data\` and lists them in `Data.xml`.
- `!!SVShim` loads first. It restores each addon's settings at that addon's `ADDON_LOADED` event, which is when the client would normally do it, so addons that set defaults while loading don't overwrite them. It also restores them once earlier, for addons that read their settings while loading (`LoadSavedVariablesFirst`).
- Per-character files only apply to the character they came from. The beta names realm folders with numbers that don't match anything visible in game, so characters are matched by name. If the same name exists on two realms, the shim skips it rather than risk applying the wrong settings.
- When the game saves, it writes the (restored) settings back to `WTF` as usual, and the script copies them again.
- The client loads *some* settings files and skips others, so the shim decides file by file. It runs its own copy of a file in a private environment and compares the result with what's already loaded. Matching content means the game loaded that file itself, so the shim leaves it alone; anything else is the addon's own defaults, so the shim restores its copy. Nothing is written into other addons' settings.
- Copies are made byte for byte, so binary data such as Auctionator's price database survives.

## Limitations

- **Blizzard's own UI settings aren't restored.** Examples are the combat log and the client's own saved settings. Blizzard's addons load before any other addon can run.
- **The script has to be running** for new changes to carry over.
- `Data\` and `Data.xml` hold **your personal settings**. They're gitignored, so don't share them unless you mean to.

## After Blizzard fixes the bug

When the client loads your settings files again, the shim finds every file already loaded and restores nothing, and you see this at login:

```
SVShim the game loaded all 13 settings files itself this session. If you see this every login, Blizzard has fixed the bug and you can close Start-SVShim and delete the !!SVShim folder.
```

This also means an outdated copy never overwrites settings the game loaded itself, even if you've stopped running the script.

While the bug is still around, a second line may list a few addons the game did load itself, for example `SVShim the game loaded these itself: HidingBar, WaypointUI`. That's expected: the client skips most files, not all of them.

## Update

Close the Start-SVShim window. Download the latest release and extract it over the old folder, replacing files when asked. Your settings data isn't in the ZIP, so it's kept. Then start `Start-SVShim.cmd` again.

## Uninstall

Close the script window and delete the `!!SVShim` folder. Your settings in `WTF` aren't touched.

## Troubleshooting

| You see | Do this |
|---|---|
| `SVShim nothing to restore` | Start `Start-SVShim.cmd`, then `/reload`. |
| `SVShim skipped <realm>/<name>: this character name exists on several realms…` | You have characters with the same name on more than one realm, so their settings can't be matched safely. Open an issue with the full line. |
| No `SVShim` line in chat at all | Check the folder is named exactly `!!SVShim` and sits directly in `AddOns` (not `AddOns\!!SVShim\!!SVShim`), and that it's enabled in the AddOns list at character select. |
| Settings still reset | Check the script window printed a line when you last `/reload`ed. If it didn't, the script wasn't running. |
