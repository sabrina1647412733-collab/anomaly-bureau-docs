param(
  [string]$Root = "",
  [string]$GodotConsole = "C:\Users\Sabrina\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.2-stable_win64_console.exe",
  [string]$GodotGui = "C:\Users\Sabrina\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.2-stable_win64.exe"
)

$ErrorActionPreference = "Stop"
if ([string]::IsNullOrWhiteSpace($Root)) {
  $Root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
}
$Root = [System.IO.Path]::GetFullPath($Root)
$P = Join-Path $Root "岚桥站0017-Godot"

if (-not (Test-Path -LiteralPath $GodotConsole)) { throw "Godot console not found: $GodotConsole" }
if (-not (Test-Path -LiteralPath $GodotGui)) { throw "Godot GUI not found: $GodotGui" }
if (-not (Test-Path -LiteralPath (Join-Path $P "project.godot"))) { throw "Project not found: $P" }

Write-Host "== headless self-check =="
& $GodotConsole --headless --path $P --quit-after 90
if ($LASTEXITCODE -ne 0) { throw "Headless self-check failed: $LASTEXITCODE" }
Write-Host "headless OK"

Write-Host "== menu screenshot =="
& $GodotGui --path $P --script res://scripts/tests/menu_shot.gd
if ($LASTEXITCODE -ne 0) { throw "menu_shot failed: $LASTEXITCODE" }

Write-Host "== panels screenshot =="
& $GodotGui --path $P --script res://scripts/tests/menu_panels_shot.gd
if ($LASTEXITCODE -ne 0) { throw "menu_panels_shot failed: $LASTEXITCODE" }

Write-Host ""
Write-Host "Screenshots:"
Get-ChildItem (Join-Path $P "_预览\截图") -Filter "menu_*_after.png" -ErrorAction SilentlyContinue | Select-Object Name,LastWriteTime | Format-Table -AutoSize

