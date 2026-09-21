# !!SVShim: keep your addon settings in the WoW Forever beta

The WoW Forever (1.60.x) beta client **saves** addon settings when you `/reload` or log out, but it **never loads them** again. Every login, your addons start from their defaults, and the next save overwrites your settings with those defaults.

!!SVShim works around this. A small script copies your saved settings into the addon folder as code. The client still loads addon code, so your settings come back.

> This is a workaround for a beta bug. Once Blizzard fixes it, delete the `!!SVShim` folder and stop using the script.

## What you need

- Windows. The script uses PowerShell, which comes with Windows.
- The WoW Forever beta, installed in the `_classic_beta_` folder.

## Install

1. Download this repo: **Code → Download ZIP** on GitHub. You can also run `git clone https://github.com/kylef000/wow-forever-svshim.git "!!SVShim"`.
2. Put it in your AddOns folder, for example:
   ```
   C:\Program Files (x86)\World of Warcraft\_classic_beta_\Interface\AddOns\!!SVShim
   ```
3. **Name the folder exactly `!!SVShim`.** A downloaded ZIP unpacks as `wow-forever-svshim-main`, so rename it. The `!!` makes it load before your other addons.

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

On login you'll see this in chat:

```
SVShim restored 16 account and 10 character settings files.
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
- `!!SVShim` loads first. Running those files puts each addon's settings back into place before the addon itself starts. Per-character files only apply to the character they came from.
- When the game saves, it writes the (restored) settings back to `WTF` as usual, and the script copies them again.

## Limitations

- **Blizzard's own UI settings aren't restored.** Examples are the combat log and the client's own saved settings. Blizzard's addons load before any other addon can run.
- **The script has to be running** for new changes to carry over.
- `Data\` and `Data.xml` hold **your personal settings**. They're gitignored, so don't share them unless you mean to.

## Uninstall

Close the script window and delete the `!!SVShim` folder. Your settings in `WTF` aren't touched.

## Troubleshooting

| You see | Do this |
|---|---|
| `SVShim nothing to restore` | Start `Start-SVShim.cmd`, then `/reload`. |
| `SVShim skipped <realm>/<name>: realm didn't match` | Open an issue with that full line. The beta names realm folders by number, and yours may differ. |
| No `SVShim` line in chat at all | Check the folder is named exactly `!!SVShim`, and that it's enabled in the AddOns list at character select. |
| Settings still reset | Check the script window printed a line when you last `/reload`ed. If it didn't, the script wasn't running. |
