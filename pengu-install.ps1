# Pengu - Persistent Linux environment in a container
# Copyright (c) 2025, Iwan van der Kleijn | MIT License
# https://github.com/soyrochus/pengu
Param(
  [switch]$Yes = $false,
  [string]$Dest = ".",
  [string]$Repo = "soyrochus/pengu",
  [string]$Ref  = "refs/heads/main"   # path variant that works in your setup
)

function Write-Info($msg) { Write-Host $msg }

function Fetch($Src, $Dst) {
  if (Test-Path $Dst -PathType Leaf -and -not $Yes) {
    $ans = Read-Host "File '$Dst' exists. Overwrite? [y/N]"
    if ($ans -notmatch '^(y|Y|yes)$') { Write-Info "Skipping $Dst"; return }
  }
  $base = "https://raw.githubusercontent.com/$Repo/$Ref"
  $url  = "$base/$Src"
  Write-Info "Fetching $Src …"
  Invoke-WebRequest -UseBasicParsing -Uri $url -OutFile $Dst
}

New-Item -ItemType Directory -Force -Path $Dest | Out-Null

# Download Dockerfile and the PowerShell helper
Fetch -Src "Dockerfile" -Dst (Join-Path $Dest "Dockerfile")
Fetch -Src "pengu.ps1"  -Dst (Join-Path $Dest "pengu.ps1")

# Also provide the Bash helper for Git Bash/WSL users (optional but handy)
Fetch -Src "pengu"      -Dst (Join-Path $Dest "pengu") 

# Try to make bash helper executable if Git Bash is present (best-effort)
try {
  bash -lc "chmod +x '$(Resolve-Path -LiteralPath (Join-Path $Dest 'pengu')).Path'"
} catch {}

Write-Host ""
Write-Host "🐧 Pengu installed in: $(Resolve-Path -LiteralPath $Dest)"
Write-Host "Next steps (PowerShell):"
Write-Host "  .\pengu.ps1 up"
Write-Host "  .\pengu.ps1 shell"
Write-Host ""
Write-Host "If you use Git Bash:"
Write-Host "  ./pengu up"
Write-Host "  ./pengu shell"
