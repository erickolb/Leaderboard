param(
    [string]$Mac = 'erickolb@barovia.chateaulore.net',
    [string]$HostKeyAlias = 'barovia.local',
    [ValidateRange(1, 2147483647)][int]$BuildNumber = 4
)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Push-Location $root
try {
    New-Item -ItemType Directory -Force build, dist | Out-Null
    $archive = Join-Path $root 'build/leaderboard-source.tar.gz'
    & tar -czf $archive --exclude=xcuserdata --exclude='*.xcuserstate' Leaderboard LeaderboardShare LeaderboardTests Leaderboard.xcodeproj scripts README.md
    if ($LASTEXITCODE -ne 0) { throw 'Could not package source files.' }
    $sshOptions = @('-o', 'BatchMode=yes', '-o', "HostKeyAlias=$HostKeyAlias", '-o', 'ConnectTimeout=15')
    $remote = & ssh @sshOptions $Mac 'mkdir -p ~/LeaderboardBuilds && mktemp -d ~/LeaderboardBuilds/build.XXXXXX'
    if ($LASTEXITCODE -ne 0) { throw 'SSH failed. Check host access and SSH-key authentication.' }
    $remote = ($remote -join "`n").Trim()
    if ($remote -notmatch '^/Users/[A-Za-z0-9._-]+/LeaderboardBuilds/build\.[A-Za-z0-9]+$') {
        throw "Unexpected remote build directory: $remote"
    }
    Write-Host "Building in $remote"
    & scp @sshOptions $archive "${Mac}:$remote/source.tar.gz"
    if ($LASTEXITCODE -ne 0) { throw 'Source transfer failed.' }
    & ssh @sshOptions $Mac "cd '$remote' && tar -xzf source.tar.gz && BUILD_NUMBER=$BuildNumber bash scripts/build-ipa.sh > build.log 2>&1; result=`$?; tail -60 build.log; exit `$result"
    if ($LASTEXITCODE -ne 0) { throw "Build failed. Log: ${Mac}:$remote/build.log" }
    & scp @sshOptions "${Mac}:$remote/dist/Leaderboard.ipa" (Join-Path $root 'dist/Leaderboard.ipa')
    if ($LASTEXITCODE -ne 0) { throw 'IPA download failed.' }
    Get-FileHash -LiteralPath (Join-Path $root 'dist/Leaderboard.ipa') -Algorithm SHA256
    Write-Host 'IPA ready at dist/Leaderboard.ipa. Import it into SideStore and keep the share extension.'
} finally {
    Pop-Location
}
