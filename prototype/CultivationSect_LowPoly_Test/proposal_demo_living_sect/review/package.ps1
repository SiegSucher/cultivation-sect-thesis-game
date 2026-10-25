$ErrorActionPreference='Stop'
if (Get-Process 'Godot*' -ErrorAction SilentlyContinue) {throw 'Close Godot before packaging.'}
$edition=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$archive=Join-Path $PSScriptRoot 'living-sect-source.zip'
if (Test-Path -LiteralPath $archive) {throw 'Recovery archive already exists; preserve it before creating another.'}
$manifest=[ordered]@{}
$files=Get-ChildItem -LiteralPath $edition -Recurse -File | Where-Object Extension -ne '.zip'
foreach ($file in $files) {
    if ($file.Extension -in @('.gd','.tscn','.cmd','.ps1','.cjs','.md','.html')) {
        $relative=$file.FullName.Substring($edition.Length+1).Replace('\','/')
        $manifest[$relative]=(Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
    }
}
$manifest | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $PSScriptRoot 'source-manifest.json') -Encoding UTF8
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
$zip=[IO.Compression.ZipFile]::Open($archive,[IO.Compression.ZipArchiveMode]::Create)
try {
    $files=Get-ChildItem -LiteralPath $edition -Recurse -File | Where-Object Extension -ne '.zip'
    foreach ($file in $files) {
        $entry='proposal_demo_living_sect/'+$file.FullName.Substring($edition.Length+1).Replace('\','/')
        [IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip,$file.FullName,$entry,[IO.Compression.CompressionLevel]::Optimal) | Out-Null
    }
} finally {$zip.Dispose()}
$zip=[IO.Compression.ZipFile]::OpenRead($archive)
$verified=0
try {
    foreach ($relative in $manifest.Keys) {
        $entry=$zip.GetEntry('proposal_demo_living_sect/'+$relative)
        if (!$entry) {throw ('Missing archive entry: '+$relative)}
        $stream=$entry.Open()
        $sha=[Security.Cryptography.SHA256]::Create()
        try {$actual=([BitConverter]::ToString($sha.ComputeHash($stream))).Replace('-','').ToLowerInvariant()}
        finally {$stream.Dispose();$sha.Dispose()}
        if ($actual -ne $manifest[$relative]) {throw ('Archive hash mismatch: '+$relative)}
        $verified++
    }
    $entryCount=$zip.Entries.Count
} finally {$zip.Dispose()}
$result=[ordered]@{archive='living-sect-source.zip';entries=$entryCount;verified_source_entries=$verified;bytes=(Get-Item -LiteralPath $archive).Length;sha256=(Get-FileHash -LiteralPath $archive -Algorithm SHA256).Hash.ToLowerInvariant();status='PASS'}
$result | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $PSScriptRoot 'recovery-verification.json') -Encoding UTF8
$result | ConvertTo-Json
