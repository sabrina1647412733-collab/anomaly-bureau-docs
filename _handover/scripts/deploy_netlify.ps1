param(
  [string]$Root = "",
  [string]$Site = "visionary-concha-bf9fea",
  [string]$Message = "更新《诡异事务局》第一季「补丁」Web 构建"
)

$ErrorActionPreference = "Stop"
if ([string]::IsNullOrWhiteSpace($Root)) {
  $Root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
}
$Root = [System.IO.Path]::GetFullPath($Root)
$DeployDir = Join-Path $Root "deploy"

if (-not (Test-Path -LiteralPath (Join-Path $DeployDir "index.html"))) {
  throw "deploy/index.html not found. Run export_web.ps1 first."
}

Write-Host "== Deploy to Netlify =="
Write-Host "Root   : $Root"
Write-Host "Dir    : $DeployDir"
Write-Host "Site   : $Site"

Push-Location $Root
try {
  npx --yes netlify deploy --prod --no-build --dir $DeployDir --site $Site --message $Message
  if ($LASTEXITCODE -ne 0) { throw "Netlify deploy failed with exit code $LASTEXITCODE" }
} finally {
  Pop-Location
}

Write-Host ""
Write-Host "Production: https://visionary-concha-bf9fea.netlify.app"
Write-Host "Verify: landing page has no '最后的地铁：0017'; game cover shows '诡异事务局'."


