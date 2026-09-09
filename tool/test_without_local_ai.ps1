$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$overridePath = Join-Path $projectRoot 'pubspec_overrides.yaml'
$previousOverride = $null
$hadOverride = Test-Path -LiteralPath $overridePath

if ($hadOverride) {
  $previousOverride = Get-Content -LiteralPath $overridePath -Raw
}

try {
  @'
dependency_overrides:
  fllama:
    path: tool/fllama_stub
'@ | Set-Content -LiteralPath $overridePath -Encoding utf8NoBOM

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

  Push-Location $projectRoot
  try {
    flutter pub get
  } finally {
    Pop-Location
  }
}
