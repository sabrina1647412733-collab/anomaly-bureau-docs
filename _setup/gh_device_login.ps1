$ErrorActionPreference = 'Stop'
$cid = 'Iv1.b507a08c87ecfe98'   # GitHub CLI 的公开 OAuth client id，支持 device flow
$tokenPath = 'F:\诡异事务局\_setup\.gh_token'

try {
    $r = Invoke-RestMethod -Uri 'https://api.github.com/rate_limit' -TimeoutSec 25
    "NET OK  api-limit=$($r.rate.limit)"
} catch {
    "NET ERR: $($_.Exception.Message)"
    exit 1
}

$d = Invoke-RestMethod -Uri 'https://github.com/login/device/code' -Method Post `
    -Body @{ client_id = $cid; scope = 'repo' } `
    -Headers @{ Accept = 'application/json' } -TimeoutSec 25

"=============================================="
"  浏览器打开: $($d.verification_uri)"
"  输入代码  : $($d.user_code)"
"  用账号    : sabrina1647412733"
"=============================================="
"CODE=$($d.user_code)"
"URL=$($d.verification_uri)"

$interval = if ($d.interval) { [int]$d.interval } else { 5 }
$deadline = (Get-Date).AddSeconds([int]$d.expires_in)
$done = $false
while ((Get-Date) -lt $deadline) {
    Start-Sleep -Seconds $interval
    try {
        $t = Invoke-RestMethod -Uri 'https://github.com/login/oauth/access_token' -Method Post `
            -Body @{
                client_id   = $cid
                device_code = $d.device_code
                grant_type  = 'urn:ietf:params:oauth:grant-type:device_code'
            } -Headers @{ Accept = 'application/json' } -TimeoutSec 25
    } catch {
        "poll-err: $($_.Exception.Message)"
        continue
    }
    if ($t.access_token) {
        Set-Content -NoNewline -Path $tokenPath -Value $t.access_token
        "TOKEN_SAVED  (scope=$($t.scope))"
        $done = $true
        break
    }
    if ($t.error -eq 'authorization_pending') { "waiting for authorization..." ; continue }
    if ($t.error) { "AUTH ERROR: $($t.error) - $($t.error_description)"; break }
}
if (-not $done) { "NOT AUTHORIZED (expired or aborted)" ; exit 2 }
