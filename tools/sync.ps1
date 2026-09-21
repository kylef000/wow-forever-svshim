<#
Copies SavedVariables files from WTF into !!SVShim\Data as addon code, and lists them in Data.xml.
The beta client writes SavedVariables but never loads them; addon code does load, so this
restores every addon's settings on the next login or /reload.

  sync.ps1                    # build once from the live WTF folder
  sync.ps1 -Watch             # rebuild after every save (keep running while playing)
  sync.ps1 -Account <name>    # pick the WTF\Account folder when there's more than one
  sync.ps1 -Source <dir>      # build once from a backup copy of WTF\Account\<name>
#>
param(
    [string]$Account,
    [string]$Source,
    [switch]$Watch
)
$ErrorActionPreference = 'Stop'

$addonDir  = Split-Path $PSScriptRoot -Parent
$addonName = Split-Path $addonDir -Leaf
$addonsDir = Split-Path $addonDir -Parent
$gameDir   = Split-Path (Split-Path $addonsDir -Parent) -Parent
$accounts  = Join-Path $gameDir 'WTF\Account'
$dataDir   = Join-Path $addonDir 'Data'
$utf8      = New-Object Text.UTF8Encoding $false

if ($addonName -ne '!!SVShim') {
    Write-Warning "This folder is named '$addonName'. Rename it to '!!SVShim' so it loads before your other addons."
}

# With several accounts, the one saved most recently is the one being played.
if (-not $Account) {
    $candidates = Get-ChildItem -LiteralPath $accounts -Directory |
        Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName 'SavedVariables') } |
        Sort-Object { (Get-Item -LiteralPath (Join-Path $_.FullName 'SavedVariables')).LastWriteTime } -Descending
    if (-not $candidates) { throw "No account folders with SavedVariables under $accounts. Log in once, then /reload." }
    $Account = $candidates[0].Name
    if (@($candidates).Count -gt 1) {
        Write-Host "Several accounts found ($(($candidates.Name) -join ', ')); using $Account. Pass -Account to choose."
    }
}
$wtfAccount = Join-Path $accounts $Account
if (-not $Source) { $Source = $wtfAccount }

# Blizzard_* files belong to Blizzard's own addons, which load before any shim can run.
function Test-Included([string]$addon) {
    if ($addon -like 'Blizzard_*' -or $addon -eq $addonName) { return $false }
    Test-Path -LiteralPath (Join-Path $addonsDir $addon)
}

function Get-SavedVariableFiles([string]$dir) {
    if (-not (Test-Path -LiteralPath $dir)) { return }
    Get-ChildItem -LiteralPath $dir -File |
        Where-Object { $_.Extension -eq '.lua' -and (Test-Included $_.BaseName) }
}

function ConvertTo-FileName([string]$text) { $text -replace '[^A-Za-z0-9_!-]', '_' }

# Write through a temp file so the client never reads a half-written file.
function Write-Atomic([string]$path, [string]$text) {
    if ((Test-Path -LiteralPath $path) -and [IO.File]::ReadAllText($path, $utf8) -ceq $text) { return }
    [IO.File]::WriteAllText("$path.tmp", $text, $utf8)
    Move-Item -LiteralPath "$path.tmp" -Destination $path -Force
}

function Build {
    $files = [ordered]@{}

    foreach ($file in Get-SavedVariableFiles (Join-Path $Source 'SavedVariables')) {
        $body = [IO.File]::ReadAllText($file.FullName, $utf8)
        $files["A_$(ConvertTo-FileName $file.BaseName).lua"] = "SVShim.Register(`"$($file.BaseName)`", function()`n$body`nend)`n"
    }

    $characters = @(Get-ChildItem -LiteralPath $Source -Directory | Where-Object Name -ne 'SavedVariables' |
        ForEach-Object { Get-ChildItem -LiteralPath $_.FullName -Directory } |
        Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName 'SavedVariables') })
    # Realm folder names can't be matched in game, so a name that appears under one realm only is matched by name.
    $realmCount = $characters | Group-Object Name -AsHashTable

    foreach ($character in $characters) {
        $realm  = $character.Parent.Name
        $unique = if ($realmCount[$character.Name].Count -eq 1) { 'true' } else { 'false' }
        foreach ($file in Get-SavedVariableFiles (Join-Path $character.FullName 'SavedVariables')) {
            $body = [IO.File]::ReadAllText($file.FullName, $utf8)
            $name = "C_$(ConvertTo-FileName $realm)_$(ConvertTo-FileName $character.Name)_$(ConvertTo-FileName $file.BaseName).lua"
            $files[$name] = "SVShim.Register(`"$($file.BaseName)`", function()`n$body`nend, `"$realm`", `"$($character.Name)`", $unique)`n"
        }
    }

    New-Item -ItemType Directory -Force -Path $dataDir | Out-Null
    foreach ($name in $files.Keys) { Write-Atomic (Join-Path $dataDir $name) $files[$name] }
    Get-ChildItem -LiteralPath $dataDir -File | Where-Object { -not $files.Contains($_.Name) } | Remove-Item

    $scripts = $files.Keys | ForEach-Object { "`t<Script file=`"Data\$_`"/>" }
    $xml = @('<Ui xmlns="http://www.blizzard.com/wow/ui/">') + $scripts + '</Ui>'
    Write-Atomic (Join-Path $addonDir 'Data.xml') (($xml -join "`n") + "`n")

    Write-Host ("[{0:HH:mm:ss}] SVShim: {1} settings files copied from {2}" -f (Get-Date), $files.Count, $Source)
}

Build
if (-not $Watch) { return }

$watcher = New-Object IO.FileSystemWatcher $wtfAccount
$watcher.IncludeSubdirectories = $true
$watcher.NotifyFilter = [IO.NotifyFilters]'FileName, LastWrite, Size'
foreach ($eventName in 'Changed', 'Created', 'Renamed') {
    Register-ObjectEvent -InputObject $watcher -EventName $eventName -SourceIdentifier "SVShim$eventName" | Out-Null
}
$watcher.EnableRaisingEvents = $true
Write-Host "Watching $wtfAccount - leave this window open while you play."

try {
    while ($true) {
        if (-not (Wait-Event -Timeout 5)) { continue }
        # A save writes dozens of files in ~100 ms; wait for the burst to finish, then rebuild once.
        do {
            Get-Event | Remove-Event
            Start-Sleep -Milliseconds 150
        } while (Get-Event)
        Build
    }
} finally {
    Get-EventSubscriber | Where-Object SourceIdentifier -like 'SVShim*' | Unregister-Event
    $watcher.Dispose()
}
