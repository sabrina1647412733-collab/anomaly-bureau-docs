# 把 Codex 上的《诡异事务局》0017 工程迁移到 F:\诡异事务局
# 用法：
#   pwsh -File F:\诡异事务局\_setup\copy_from_codex.ps1
#   pwsh -File F:\诡异事务局\_setup\copy_from_codex.ps1 -NoGit      # 不复制 .git 历史
#   pwsh -File F:\诡异事务局\_setup\copy_from_codex.ps1 -WhatIfOnly  # 只打印计划

[CmdletBinding()]
param(
    [switch]$NoGit,
    [switch]$WhatIfOnly,
    [switch]$Force
)

$ErrorActionPreference = 'Stop'

$src = 'C:\Users\Sabrina\Documents\ChatGPT\最后的地铁：0017'
$dst = 'F:\诡异事务局'

if (-not (Test-Path -LiteralPath $src)) { throw "源目录不存在：$src" }
if (-not (Test-Path -LiteralPath "$src\岚桥站0017-Godot\project.godot")) {
    throw "源工程不完整，找不到 project.godot"
}

# robocopy 退出码 0-7 视为成功
function Invoke-Robocopy {
    param([string]$From, [string]$To, [string[]]$Extra = @())
    $roboArgs = @($From, $To, '/E', '/NFL', '/NDL', '/NJH', '/NJS', '/NP', '/R:1', '/W:1') + $Extra
    if ($WhatIfOnly) { $roboArgs += '/L' }
    Write-Host ("  robocopy -> {0}" -f $To) -ForegroundColor DarkGray
    & robocopy @roboArgs | Out-Null
    $code = $LASTEXITCODE
    if ($code -ge 8) { throw "robocopy 失败（code=$code）：$From -> $To" }
}

$excludeDirs = @('.godot', '_预览')

Write-Host "== 源：$src"
Write-Host "== 目标：$dst"
Write-Host "== Git 历史：$(if ($NoGit) { '跳过' } else { '保留' })"

if ($WhatIfOnly) {
    Write-Host "== [WhatIfOnly] 只列出计划，不写文件" -ForegroundColor Yellow
} else {
    New-Item -ItemType Directory -Force -Path $dst | Out-Null
}

# 1) Godot 主工程（源码 + assets + .git，排除导入缓存和开发截图）
$godotX  = @('/XD') + $excludeDirs
if ($NoGit) { $godotX += @('.git') }
Invoke-Robocopy -From "$src\岚桥站0017-Godot" -To "$dst\岚桥站0017-Godot" -Extra $godotX

# 2) 线上构建
if (Test-Path -LiteralPath "$src\deploy") {
    Invoke-Robocopy -From "$src\deploy" -To "$dst\deploy"
}

# 3) 交接资料（跳过 145 MB 的 zip/bundle，原盘还在 C:）
if (Test-Path -LiteralPath "$src\_handover") {
    Invoke-Robocopy -From "$src\_handover" -To "$dst\_handover" -Extra @('/XF', '*.zip', '*.bundle')
}

# 4) 根目录文档 / 剧本 / 启动与录制脚本 / Netlify 状态
$rootFiles = @(
    '剧本_最后的地铁_0017_完整季_v5.md',
    '世界观圣经_诡异事务局.md',
    '0017前_序章场景与流程.md',
    '剧本_0017_当前版_v4.md',
    '剧本_0017_丰富版.md',
    '剧本_0017_丰富版_v2.md',
    '剧本_0017_制作版_v3.md',
    '剧本_0018_0号线_剧情大纲.md',
    '剧本_0018_17楼_剧情大纲.md',
    '剧本_0018_17楼_剧情大纲_单主角版.md',
    'Godot录制说明.md',
    '启动岚桥站0017-游戏.bat',
    '录制-岚桥站0017.bat',
    '录制-岚桥站0017-MovieMaker.bat',
    '.gitignore'
)
foreach ($f in $rootFiles) {
    $p = Join-Path $src $f
    if (Test-Path -LiteralPath $p) {
        if (-not $WhatIfOnly) { Copy-Item -LiteralPath $p -Destination $dst -Force }
        Write-Host ("  copy {0}" -f $f) -ForegroundColor DarkGray
    } else {
        Write-Host ("  ! 缺少 {0}（跳过）" -f $f) -ForegroundColor Yellow
    }
}
if (Test-Path -LiteralPath "$src\.netlify\state.json") {
    if (-not $WhatIfOnly) {
        New-Item -ItemType Directory -Force -Path "$dst\.netlify" | Out-Null
        Copy-Item -LiteralPath "$src\.netlify\state.json" -Destination "$dst\.netlify" -Force
    }
    Write-Host "  copy .netlify\state.json" -ForegroundColor DarkGray
}

# 5) 汇总
if (-not $WhatIfOnly) {
    Write-Host ""
    Write-Host "== 完成，核对结果：" -ForegroundColor Green
    $need = @(
        '岚桥站0017-Godot\project.godot',
        '岚桥站0017-Godot\scripts\game.gd',
        '岚桥站0017-Godot\scripts\menu.gd',
        '岚桥站0017-Godot\assets\ui\menu_bureau_bg.png',
        '岚桥站0017-Godot\export_presets.cfg',
        'deploy\index.html',
        'deploy\game\index.pck',
        'deploy\game\index.wasm'
    )
    $bad = 0
    foreach ($n in $need) {
        $ok = Test-Path -LiteralPath (Join-Path $dst $n)
        if (-not $ok) { $bad++ }
        Write-Host ("  [{0}] {1}" -f $(if ($ok) { 'OK' } else { '缺失' }), $n) -ForegroundColor $(if ($ok) { 'Gray' } else { 'Red' })
    }
    $pck = Join-Path $dst 'deploy\game\index.pck'
    if (Test-Path -LiteralPath $pck) {
        $len = (Get-Item -LiteralPath $pck).Length
        Write-Host ("  index.pck = {0} 字节（清单值 78802808）" -f $len) -ForegroundColor $(if ($len -eq 78802808) { 'Gray' } else { 'Yellow' })
    }
    $gitDir = Join-Path $dst '岚桥站0017-Godot\.git'
    if (-not $NoGit) {
        Write-Host ("  .git 已复制：{0}" -f (Test-Path -LiteralPath $gitDir)) -ForegroundColor DarkGray
    }
    if ($bad -gt 0) { throw "有 $bad 个关键文件缺失" }
}
