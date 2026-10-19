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
# Godot 导出会把工程名写成标签（岚桥站 0017）。统一改成《诡异事务局》，
# 并在引擎启动完成时设置一次标题；不要用 setInterval 轮询。
$html = [System.IO.File]::ReadAllText($OutHtml, [System.Text.Encoding]::UTF8)
$title = '诡异事务局 · 第一季「补丁」'
$html = [regex]::Replace($html, '(?s)<title>.*?</title>', "<title>$title</title>")

$titleSet = "`n`t`t`t// 引擎启动会按工程名改写标题；启动完成后只设置一次，不再轮询。`n`t`t`tdocument.title = '$title';"
$hook = @'
(\}\)\.then\(\(\) => \{\s*setStatusMode\('hidden'\);)
'@
if ($html -notmatch $hook) {
  throw "Failed to patch startup title: setStatusMode('hidden') hook not found in exported index.html"
}
$html = $html -replace $hook, ('$1' + $titleSet)
if ($html -notmatch [regex]::Escape("document.title = '$title'")) {
  throw "Failed to insert one-time title assignment"
}
if ($html -match 'setInterval\(function\(\)\{document\.title') {
  throw "Legacy setInterval title hack still present in exported index.html"
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





