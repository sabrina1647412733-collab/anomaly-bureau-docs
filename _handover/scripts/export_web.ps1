param(
  [string]$Root = "",
  [string]$Godot = "C:\Users\Sabrina\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.2-stable_win64_console.exe",
  [switch]$Zip
)

$ErrorActionPreference = "Stop"
if ([string]::IsNullOrWhiteSpace($Root)) {
  $Root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
}
$Root = [System.IO.Path]::GetFullPath($Root)
$Project = Join-Path $Root "岚桥站0017-Godot"
$OutHtml = Join-Path $Root "deploy\game\index.html"

if (-not (Test-Path -LiteralPath $Godot)) { throw "Godot not found: $Godot" }
if (-not (Test-Path -LiteralPath (Join-Path $Project "project.godot"))) { throw "Godot project not found: $Project" }

Write-Host "== Export Web =="
Write-Host "Project: $Project"
Write-Host "Output : $OutHtml"
& $Godot --headless --path $Project --export-release "Web" $OutHtml
if ($LASTEXITCODE -ne 0) { throw "Godot export failed with exit code $LASTEXITCODE" }

Write-Host "== Patch browser title =="
$html = [System.IO.File]::ReadAllText($OutHtml, [System.Text.Encoding]::UTF8)
$html = $html.Replace('<title>岚桥站 0017</title>', '<title>诡异事务局 · 第一季「补丁」</title>')
$titleScript = "<script>setInterval(function(){document.title='诡异事务局 · 第一季「补丁」';},500);</script>"
if ($html -notmatch "document.title='诡异事务局") {
  $html = $html.Replace("</head>", $titleScript + "`n</head>")
  if ($html -notmatch "document.title='诡异事务局") {
    throw "Failed to insert title script: </head> not found in exported index.html"
  }
}
[System.IO.File]::WriteAllText($OutHtml, $html, [System.Text.UTF8Encoding]::new($false))

$pck = Join-Path $Root "deploy\game\index.pck"
$wasm = Join-Path $Root "deploy\game\index.wasm"
if (Test-Path -LiteralPath $pck) {
  $m = Get-Item -LiteralPath $pck
  Write-Host ("index.pck: {0:N2} MB" -f ($m.Length / 1MB))
}
if (Test-Path -LiteralPath $wasm) {
  $m = Get-Item -LiteralPath $wasm
  Write-Host ("index.wasm: {0:N2} MB" -f ($m.Length / 1MB))
}

if ($Zip) {
  Write-Host "== Repack zips =="
  $game = Join-Path $Root "deploy\game"
  $zip1 = Join-Path $Root "0017-网页版.zip"
  $zip2 = Join-Path $Root "0017-网页版-完整站点-20261019.zip"
  Compress-Archive -Path (Join-Path $game "*") -DestinationPath $zip1 -CompressionLevel Optimal -Force
  Compress-Archive -Path (Join-Path $Root "deploy\*") -DestinationPath $zip2 -CompressionLevel Optimal -Force
  Get-Item -LiteralPath $zip1, $zip2 | Select-Object Name, @{n='MB';e={[math]::Round($_.Length/1MB,2)}} | Format-Table -AutoSize
}

Write-Host "Done. Next: powershell -File `"$PSScriptRoot\deploy_netlify.ps1`""





