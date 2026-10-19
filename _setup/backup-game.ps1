[Console]::OutputEncoding = [Text.Encoding]::UTF8
$ErrorActionPreference = 'Continue'

$repo = Join-Path (Split-Path -Parent $PSScriptRoot) '岚桥站0017-Godot'
$name = 'anomaly-bureau-game'

Write-Host '============================================' -ForegroundColor Cyan
Write-Host "  备份 Godot 主工程  ->  $name" -ForegroundColor Cyan
Write-Host '============================================' -ForegroundColor Cyan

if (-not (Test-Path $repo)) {
    Write-Host "[错误] 找不到工程目录：$repo" -ForegroundColor Red
    exit 1
}
Set-Location -LiteralPath $repo

git add -A
git diff --cached --quiet
if ($LASTEXITCODE -eq 0) {
    Write-Host '没有新改动，检查远端同步...' -ForegroundColor Yellow
    git push
    if ($LASTEXITCODE -eq 0) { Write-Host '已是最新。' -ForegroundColor Green }
    exit $LASTEXITCODE
}

Write-Host '本次改动：' -ForegroundColor Yellow
git -c core.quotepath=false status --short

$msg = Read-Host '提交说明（直接回车 = 用时间）'
if ([string]::IsNullOrWhiteSpace($msg)) {
    $msg = '自动备份 ' + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
}

git commit -m $msg
if ($LASTEXITCODE -ne 0) {
    Write-Host '[失败] 提交失败，把上面的红字发给我。' -ForegroundColor Red
    exit 1
}

git push
if ($LASTEXITCODE -ne 0) {
    Write-Host '[失败] 推送失败。常见原因：代理没开（需 127.0.0.1:7897）或需要重新登录 GitHub。' -ForegroundColor Red
    exit 1
}
Write-Host '完成。' -ForegroundColor Green
