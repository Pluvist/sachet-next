param(
    [string]$BuildDirectory = "$env:LOCALAPPDATA\XachetNativeBuild",
    [string]$JavaDirectory = 'C:\Program Files\Android\Android Studio\jbr',
    [string[]]$Tasks = @(':app:assembleDebug', ':app:testDebugUnitTest'),
    [switch]$Offline
)
$ErrorActionPreference = 'Stop'
$sourceRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
New-Item -ItemType Directory -Force $BuildDirectory | Out-Null
foreach ($legal in @('LICENSE', 'LICENSE-MIT', 'THIRD_PARTY_NOTICES.md')) {
    Copy-Item -LiteralPath (Join-Path $sourceRoot $legal) -Destination (Join-Path $BuildDirectory $legal) -Force
}
if ($BuildDirectory -match '[^\x00-\x7F]') { throw 'The native CMake build needs an ASCII build directory on Windows.' }
foreach ($part in @('native', 'third_party\glasmio')) {
    $source = Join-Path $sourceRoot $part
    $target = Join-Path $BuildDirectory $part
    New-Item -ItemType Directory -Force $target | Out-Null
    & robocopy $source $target /E /XD build .gradle .kotlin .cxx artifacts /XF '*.log' /NFL /NDL /NJH /NJS /NP
    if ($LASTEXITCODE -gt 7) { throw "Build staging failed for $part" }
}
if (Test-Path -LiteralPath $JavaDirectory) { $env:JAVA_HOME = $JavaDirectory }
$arguments = @('-p', (Join-Path $BuildDirectory 'native')) + $Tasks + @('--max-workers=2', '--console=plain')
if ($Offline) { $arguments += '--offline' }
& (Join-Path $BuildDirectory 'native\gradlew.bat') @arguments
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
Get-ChildItem -LiteralPath "$BuildDirectory\native\app\build\outputs\apk" -Recurse -Filter '*.apk' | ForEach-Object { Write-Output "APK: $($_.FullName)" }
