$ErrorActionPreference = 'Stop'
$stage = Join-Path ([IO.Path]::GetTempPath()) ('hyperos-hotword-' + [Guid]::NewGuid())
try {
    New-Item -ItemType Directory $stage | Out-Null
    foreach ($name in @('module.prop', 'customize.sh', 'service.sh', 'prepare.sh')) {
        Copy-Item (Join-Path $PSScriptRoot $name) $stage
    }
    Copy-Item (Join-Path $PSScriptRoot 'system') $stage -Recurse
    if (Test-Path (Join-Path $stage 'system/priv-app/HyperOS4Google')) { throw 'Distributed ZIP must not contain Google App APKs' }
    if (Test-Path (Join-Path $stage 'system/etc/permissions/privapp-hyperos4-google-hotword.xml')) { throw 'Google permission policy must be generated on the user device' }
    Add-Type -AssemblyName System.IO.Compression
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $output = Join-Path (Split-Path $PSScriptRoot) 'HyperOS4-Google-Hotword-v1.2.zip'
    if (Test-Path $output) { Remove-Item $output }
    $archive = [IO.Compression.ZipFile]::Open($output, [IO.Compression.ZipArchiveMode]::Create)
    try {
        foreach ($file in Get-ChildItem -File -Recurse $stage) {
            $member = $file.FullName.Substring($stage.Length + 1).Replace('\', '/')
            [IO.Compression.ZipFileExtensions]::CreateEntryFromFile($archive, $file.FullName, $member) | Out-Null
        }
    } finally { $archive.Dispose() }
    Write-Output "Built $output without Google App APKs or device data."
} finally {
    if (Test-Path $stage) { Remove-Item -Recurse -Force $stage }
}
