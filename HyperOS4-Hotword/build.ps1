param([string]$Serial, [string]$OfflineBaseZip)
$ErrorActionPreference = 'Stop'
$adb = if (!$OfflineBaseZip) { (Get-Command adb).Source }
function Invoke-Adb([string[]]$AdbArgs) {
    $result = & $adb -s $Serial @AdbArgs
    if ($LASTEXITCODE -ne 0) { throw "adb failed: $AdbArgs" }
    return $result
}
$stage = Join-Path ([IO.Path]::GetTempPath()) ('hyperos-hotword-' + [Guid]::NewGuid())
try {
    $app = Join-Path $stage 'system/priv-app/HyperOS4Google'
    $permissionsDir = Join-Path $stage 'system/etc/permissions'
    New-Item -ItemType Directory -Force $app, $permissionsDir | Out-Null
    Copy-Item (Join-Path $PSScriptRoot 'module.prop'), (Join-Path $PSScriptRoot 'customize.sh'), (Join-Path $PSScriptRoot 'service.sh') $stage
    if ($OfflineBaseZip) {
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        $base = [IO.Compression.ZipFile]::OpenRead((Resolve-Path $OfflineBaseZip).Path)
        try {
            foreach ($entry in $base.Entries) {
                if ($entry.FullName -match '^system/priv-app/HyperOS4Google/[^/]+\.apk$|^system/etc/permissions/privapp-hyperos4-google-hotword\.xml$') {
                    [IO.Compression.ZipFileExtensions]::ExtractToFile($entry, (Join-Path $stage $entry.FullName), $false)
                }
            }
        } finally { $base.Dispose() }
        if (!(Test-Path (Join-Path $app 'base.apk')) -or !(Test-Path (Join-Path $permissionsDir 'privapp-hyperos4-google-hotword.xml'))) { throw 'Offline base lacks Google payload or device permission policy' }
    } else {
    if (!$Serial) { throw 'Specify -Serial for the current device or -OfflineBaseZip for a previously captured device-specific package' }
    $paths = Invoke-Adb @('shell', 'pm', 'path', 'com.google.android.googlequicksearchbox')
    foreach ($line in $paths) {
        if ($line -notmatch '^package:(.+)$') { throw "Unexpected package path: $line" }
        $source = $Matches[1].Trim()
        Invoke-Adb @('pull', $source, (Join-Path $app ([IO.Path]::GetFileName($source)))) | Out-Null
    }
    if (!(Test-Path (Join-Path $app 'base.apk'))) { throw 'Google base.apk missing' }
    $definitions = (Invoke-Adb @('shell', 'pm', 'list', 'permissions', '-f')) -join "`n"
    $package = (Invoke-Adb @('shell', 'dumpsys', 'package', 'com.google.android.googlequicksearchbox')) -join "`n"
    $requestedBlock = [regex]::Match($package, '(?ms)^    requested permissions:\s*\n(.*?)(?=^    [^ ])').Groups[1].Value
    $requested = [regex]::Matches($requestedBlock, 'android\.permission\.[A-Z_0-9]+') | ForEach-Object { $_.Value }
    if (!$requested) { throw 'Requested permission parsing failed' }
    $grants = @('android.permission.CAPTURE_AUDIO_HOTWORD', 'android.permission.MANAGE_SOUND_TRIGGER', 'android.permission.MANAGE_VOICE_KEYPHRASES', 'android.permission.SOUND_TRIGGER_RUN_IN_BATTERY_SAVER')
    $entries = @()
    foreach ($block in [regex]::Split($definitions, '(?m)^\+ permission:')) {
        $name = ($block -split '\r?\n')[0].Trim()
        if ($block -match '(?m)^  package:android\r?$' -and $block -match '(?m)^  protectionLevel:.*\bprivileged\b' -and $requested -contains $name) {
            $tag = if ($grants -contains $name) { 'permission' } else { 'deny-permission' }
            $entries += "    <$tag name=`"$name`"/>"
        }
    }
    foreach ($grant in $grants) { if (!($entries -contains "    <permission name=`"$grant`"/>")) { throw "Missing required grant: $grant" } }
    $xml = "<?xml version=`"1.0`" encoding=`"utf-8`"?>`n<permissions>`n  <privapp-permissions package=`"com.google.android.googlequicksearchbox`">`n" + ($entries -join "`n") + "`n  </privapp-permissions>`n</permissions>`n"
    [IO.File]::WriteAllText((Join-Path $permissionsDir 'privapp-hyperos4-google-hotword.xml'), $xml, [Text.UTF8Encoding]::new($false))
    }
    Copy-Item (Join-Path $PSScriptRoot 'system') $stage -Recurse -Force
    Add-Type -AssemblyName System.IO.Compression
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $output = Join-Path (Split-Path $PSScriptRoot) 'HyperOS4-Google-Hotword-v1.1-candidate.zip'
    if (Test-Path $output) { Remove-Item $output }
    $archive = [IO.Compression.ZipFile]::Open($output, [IO.Compression.ZipArchiveMode]::Create)
    try {
        foreach ($file in Get-ChildItem -File -Recurse $stage) {
            $member = $file.FullName.Substring($stage.Length + 1).Replace('\', '/')
            [IO.Compression.ZipFileExtensions]::CreateEntryFromFile($archive, $file.FullName, $member) | Out-Null
        }
    } finally { $archive.Dispose() }
    Write-Output "Built $output with captured Google APKs, device permission policy and original myron hardware enrollment components. Device verification required."
} finally {
    if (Test-Path $stage) { Remove-Item -Recurse -Force $stage }
}
