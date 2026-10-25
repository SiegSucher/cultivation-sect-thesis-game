$ErrorActionPreference='Stop'
if (Get-Process 'Godot*' -ErrorAction SilentlyContinue) {throw 'Close Godot before cleanup.'}
$project=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$workspace=[IO.Path]::GetFullPath((Join-Path $project '../..'))
$archiveRoot=Join-Path $workspace 'prototype\_proposal_archive\2026-10-25-living-sect-cleanup'
$manifest=Get-Content -LiteralPath (Join-Path $archiveRoot 'cleanup-manifest.json') -Raw | ConvertFrom-Json
$verified=Get-Content -LiteralPath (Join-Path $archiveRoot 'backup-verification.json') -Raw | ConvertFrom-Json
$hashes=Get-Content -LiteralPath (Join-Path $archiveRoot 'archived-sha256.json') -Raw | ConvertFrom-Json
if ($verified.status -ne 'VERIFIED' -or $verified.files -ne $manifest.files.Count) {throw 'Backup not fully verified.'}
foreach ($file in $manifest.files) {
    $expected=$hashes.PSObject.Properties[$file.entry].Value
    $actual=(Get-FileHash -LiteralPath $file.absolute -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($actual -ne $expected) {throw ('File changed since backup: '+$file.absolute)}
}
# Resolve and validate every complete target before any recursive removal.
$targets=@()
$allowedWorkspaceFiles=@('View Mountain Valley Blockout.cmd','View Phase 4A Main Sect Hall.cmd')
foreach ($entry in $manifest.delete_roots) {
    $base=if ($entry.root -eq 'project') {$project} else {$workspace}
    $target=[IO.Path]::GetFullPath((Join-Path $base $entry.relative))
    if ($entry.root -eq 'project') {
        if (!$target.StartsWith($project+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)) {throw ('Unsafe target: '+$target)}
        if ($target.StartsWith((Join-Path $project 'proposal_demo_living_sect'),[StringComparison]::OrdinalIgnoreCase)) {throw 'Cannot delete selected demo.'}
    } elseif ($entry.relative -notin $allowedWorkspaceFiles -or [IO.Path]::GetDirectoryName($target) -ne $workspace) {throw ('Unapproved workspace target: '+$target)}
    $item=Get-Item -LiteralPath $target -Force
    if ($item.LinkType -in @('Junction','SymbolicLink')) {throw ('Linked directory requires separate inspection: '+$target)}
    $targets+=@{path=$target;directory=$item.PSIsContainer}
}
$deleted=@()
foreach ($target in $targets) {
    if ($target.directory) {Remove-Item -LiteralPath $target.path -Recurse -Force}
    else {Remove-Item -LiteralPath $target.path -Force}
    if (Test-Path -LiteralPath $target.path) {throw ('Removal incomplete: '+$target.path)}
    $deleted+=$target.path
}
$result=[ordered]@{status='CLEANED';completed_at=(Get-Date).ToString('o');deleted_roots=$deleted;deleted_files=($manifest.files | Where-Object action -eq 'DELETE_AFTER_BACKUP').Count;backup=$verified.archive;backup_bytes=$verified.bytes;gameplay_source_modified=$false}
$result | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $PSScriptRoot 'cleanup-receipt.json') -Encoding UTF8
$result | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $archiveRoot 'cleanup-receipt.json') -Encoding UTF8
Write-Output ('Removed '+$deleted.Count+' obsolete roots; verified backup retained at '+$archiveRoot)
