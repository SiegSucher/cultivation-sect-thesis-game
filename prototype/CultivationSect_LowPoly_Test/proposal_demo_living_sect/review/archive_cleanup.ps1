$ErrorActionPreference='Stop'
if (Get-Process 'Godot*' -ErrorAction SilentlyContinue) {throw 'Close Godot before cleanup.'}
$project=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$workspace=[IO.Path]::GetFullPath((Join-Path $project '../..'))
$archiveRoot=Join-Path $workspace 'prototype\_proposal_archive\2026-10-25-living-sect-cleanup'
$manifest=Get-Content -LiteralPath (Join-Path $archiveRoot 'cleanup-manifest.json') -Raw | ConvertFrom-Json
$zipPath=Join-Path $archiveRoot 'retired-files.zip'
if (Test-Path -LiteralPath $zipPath) {throw 'Archive already exists; do not overwrite recovery data.'}
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
$zip=[IO.Compression.ZipFile]::Open($zipPath,[IO.Compression.ZipArchiveMode]::Create)
$hashes=[ordered]@{}
try {
    $i=0
    foreach ($file in $manifest.files) {
        $source=[IO.Path]::GetFullPath($file.absolute)
        if (!$source.StartsWith($workspace+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)) {throw ('Outside workspace: '+$source)}
        $hashes[$file.entry]=(Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash.ToLowerInvariant()
        $compression=if ([IO.Path]::GetExtension($source) -in @('.zip','.png','.jpg','.jpeg','.webp','.glb','.blend')) {[IO.Compression.CompressionLevel]::NoCompression} else {[IO.Compression.CompressionLevel]::Fastest}
        [IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip,$source,$file.entry,$compression) | Out-Null
        $i++
        if ($i % 1500 -eq 0) {Write-Output ('Archived '+$i+' files')}
    }
} finally {$zip.Dispose()}
$hashes | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $archiveRoot 'archived-sha256.json') -Encoding UTF8
$zip=[IO.Compression.ZipFile]::OpenRead($zipPath)
$verified=0
try {
    foreach ($key in $hashes.Keys) {
        $entry=$zip.GetEntry($key)
        if (!$entry) {throw ('Missing archive entry: '+$key)}
        $stream=$entry.Open();$sha=[Security.Cryptography.SHA256]::Create()
        try {$hash=([BitConverter]::ToString($sha.ComputeHash($stream))).Replace('-','').ToLowerInvariant()}
        finally {$stream.Dispose();$sha.Dispose()}
        if ($hash -ne $hashes[$key]) {throw ('Archive mismatch: '+$key)}
        $verified++
    }
} finally {$zip.Dispose()}
[ordered]@{status='VERIFIED';files=$verified;archive=$zipPath;bytes=(Get-Item -LiteralPath $zipPath).Length;checked_at=(Get-Date).ToString('o')} | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $archiveRoot 'backup-verification.json') -Encoding UTF8
Write-Output ('Verified every archived file: '+$verified+'. No files deleted yet.')
