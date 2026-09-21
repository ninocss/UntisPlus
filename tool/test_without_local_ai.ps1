$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$overridePath = Join-Path $projectRoot 'pubspec_overrides.yaml'
$lockPath = Join-Path $projectRoot 'pubspec.lock'
$previousOverride = $null
$hadOverride = Test-Path -LiteralPath $overridePath
$previousLock = if (Test-Path -LiteralPath $lockPath) {
  [System.IO.File]::ReadAllBytes($lockPath)
} else {
  $null
}

if ($hadOverride) {
  $previousOverride = Get-Content -LiteralPath $overridePath -Raw
}

try {
  @'
dependency_overrides:
  fllama:
    path: tool/fllama_stub
'@ | Set-Content -LiteralPath $overridePath -Encoding UTF8

  Push-Location $projectRoot
  try {
    flutter pub get
    if ($LASTEXITCODE -ne 0) { throw 'flutter pub get failed' }
    flutter test --no-pub @args
    if ($LASTEXITCODE -ne 0) { throw 'flutter test failed' }
  } finally {
    Pop-Location
  }
} finally {
  if ($hadOverride) {
    Set-Content -LiteralPath $overridePath -Value $previousOverride -NoNewline
  } elseif (Test-Path -LiteralPath $overridePath) {
    Remove-Item -LiteralPath $overridePath
  }

  if ($null -ne $previousLock) {
    [System.IO.File]::WriteAllBytes($lockPath, $previousLock)
  }

  Push-Location $projectRoot
  try {
    flutter pub get --offline --enforce-lockfile
    if ($LASTEXITCODE -ne 0) { throw 'restoring production dependencies failed' }
  } finally {
    Pop-Location
  }

  # Pub must not turn a test run into an unrelated lockfile update.
  if ($null -ne $previousLock) {
    [System.IO.File]::WriteAllBytes($lockPath, $previousLock)
  }
}
