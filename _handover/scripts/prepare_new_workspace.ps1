param(
  [Parameter(Mandatory = $true)][string]$Destination,
  [switch]$WithGit,
  [switch]$WithPreviews,
  [switch]$WithCourseRepo
)

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$Dest = [System.IO.Path]::GetFullPath($Destination)

if (Test-Path -LiteralPath $Dest) {
  $existing = @(Get-ChildItem -LiteralPath $Dest -Force -ErrorAction SilentlyContinue)
  if ($existing.Count -gt 0) {
    throw "Destination already exists and is not empty: $Dest"
  }
} else {
  New-Item -ItemType Directory -Force -Path $Dest | Out-Null
}

function Copy-Tree([string]$Src, [string]$Dst, [string[]]$ExcludeDirs = @()) {
  if (-not (Test-Path -LiteralPath $Src)) { return }
  New-Item -ItemType Directory -Force -Path $Dst | Out-Null
  $rcArgs = @($Src, $Dst, "/E", "/NFL", "/NDL", "/NJH", "/NJS", "/nc", "/ns", "/np")
  if ($ExcludeDirs.Count -gt 0) {
    $rcArgs += "/XD"
    $rcArgs += $ExcludeDirs
  }
  & robocopy @rcArgs | Out-Null
  if ($LASTEXITCODE -ge 8) { throw "robocopy failed ($LASTEXITCODE): $Src -> $Dst" }
}

Write-Host "== Prepare new workspace =="
Write-Host "Source: $Root"
Write-Host "Dest  : $Dest"

$projSrc = Join-Path $Root "岚桥站0017-Godot"
$projDst = Join-Path $Dest "岚桥站0017-Godot"
$exclude = @((Join-Path $projSrc ".godot"))
if (-not $WithGit) { $exclude += (Join-Path $projSrc ".git") }
if (-not $WithPreviews) { $exclude += (Join-Path $projSrc "_预览") }
Copy-Tree $projSrc $projDst $exclude

Copy-Tree (Join-Path $Root "deploy") (Join-Path $Dest "deploy")
Copy-Tree (Join-Path $Root "_handover") (Join-Path $Dest "_handover")
Copy-Tree (Join-Path $Root ".netlify") (Join-Path $Dest ".netlify")
Copy-Tree (Join-Path $Root "_automation") (Join-Path $Dest "_automation")

if ($WithPreviews) {
  Copy-Tree (Join-Path $Root "_预览") (Join-Path $Dest "_预览")
}
if ($WithCourseRepo) {
  Copy-Tree (Join-Path $Root "0017_1-repo") (Join-Path $Dest "0017_1-repo")
}

$files = @(
  "剧本_最后的地铁_0017_完整季_v5.md",
  "世界观圣经_诡异事务局.md",
  "0017前_序章场景与流程.md",
  "剧本_0017_当前版_v4.md",
  "剧本_0017_丰富版_v2.md",
  "剧本_0017_丰富版.md",
  "剧本_0017_制作版_v3.md",
  "剧本_0018_0号线_剧情大纲.md",
  "剧本_0018_17楼_剧情大纲.md",
  "剧本_0018_17楼_剧情大纲_单主角版.md",
  "Godot录制说明.md",
  "启动岚桥站0017-游戏.bat",
  "录制-岚桥站0017.bat",
  "录制-岚桥站0017-MovieMaker.bat",
  ".gitignore"
)
foreach ($f in $files) {
  $src = Join-Path $Root $f
  if (Test-Path -LiteralPath $src) {
    Copy-Item -LiteralPath $src -Destination (Join-Path $Dest $f) -Force
  }
}

$m = Get-ChildItem -LiteralPath $Dest -Recurse -File -ErrorAction SilentlyContinue | Measure-Object Length -Sum
Write-Host ""
Write-Host "Done."
Write-Host ("Files: {0}" -f $m.Count)
Write-Host ("Size : {0:N1} MB" -f ($m.Sum / 1MB))
Write-Host ("Open : " + (Join-Path $Dest "岚桥站0017-Godot\project.godot"))
if (-not $WithGit) {
  Write-Host "Note: .git was not copied. History is in _handover\patches\Godot_Git历史_20261019.bundle if present."
}
if (-not $WithPreviews) {
  Write-Host "Note: Godot _预览 was not copied. Recreate screenshots with verify_godot.ps1."
}

