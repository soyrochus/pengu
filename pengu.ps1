# Pengu - Persistent Linux environment in a container (Windows-only)
# Copyright (c) 2025, Iwan van der Kleijn | MIT License
# https://github.com/soyrochus/pengu

Param(
  [Parameter(Mandatory=$false, Position=0)]
  [ValidateSet("up","shell","root","stop","rm","rebuild","commit","nuke","profile","help")]
  [string]$Cmd = "",

  # For normal commands: PROFILE defaults to 'default'
  # For 'profile' command: this parameter is NOT used as a Pengu profile
  [Parameter(Mandatory=$false, Position=1)]
  [string]$Profile = "default",

  # Remaining arguments (used by `profile` subcommands)
  [Parameter(ValueFromRemainingArguments=$true)]
  [string[]]$Rest = @()
)

function Get-Engine {
  if (Get-Command podman -ErrorAction SilentlyContinue) { return "podman" }
  elseif (Get-Command docker -ErrorAction SilentlyContinue) { return "docker" }
  else { throw "Need podman or docker in PATH." }
}

function Slugify([string]$s) {
  if ([string]::IsNullOrWhiteSpace($s)) { return "default" }
  $t = $s.ToLowerInvariant()
  $t = [regex]::Replace($t, '[^a-z0-9_.-]+', '-')
  $t = [regex]::Replace($t, '-{2,}', '-')
  $t = $t.Trim('-')
  if ([string]::IsNullOrWhiteSpace($t)) { return "default" }
  return $t
}

$ENG = Get-Engine

# If Podman is present on Windows, it commonly requires a running machine/VM.
if ($ENG -eq "podman") {
  try {
    & podman machine inspect *> $null
    if ($LASTEXITCODE -ne 0) {
      Write-Warning "Podman machine not running. Try: podman machine start"
    }
  } catch {
    # Ignore; podman may not have machine subcommand in some setups.
  }
}

$ProjectRaw = if ($env:PROJECT_NAME) { $env:PROJECT_NAME } else { Split-Path -Leaf (Get-Location) }
$ProjectSafe = Slugify $ProjectRaw

# Windows default UID/GID (kept fixed by design)
$Uid = if ($env:PENGU_UID) { [int]$env:PENGU_UID } else { 1000 }
$Gid = if ($env:PENGU_GID) { [int]$env:PENGU_GID } else { 1000 }

# Workspace mount needs :U on Podman to avoid EACCES on bind mounts.
$WorkspaceSuffix = if ($ENG -eq "podman") { ":U" } else { "" }

# Host path for bind mount
$HostPath = (Get-Location).Path

function Resolve-PenguFile {
  param([string]$Name)

  $base = ".pengu"

  if ($Name -eq "default") {
    $path = Join-Path $base "Pengufile"
    if (Test-Path $path -PathType Leaf) { return $path }

    if (Test-Path "Dockerfile" -PathType Leaf) {
      Write-Warning "Using Dockerfile is deprecated."
      Write-Warning "Please migrate to .pengu/Pengufile."
      return "Dockerfile"
    }
  } else {
    $path = Join-Path $base ("Pengufile.{0}" -f $Name)
    if (Test-Path $path -PathType Leaf) { return $path }
  }

  $expected = if ($Name -eq "default") { "$base/Pengufile" } else { "$base/Pengufile.$Name" }
  throw "Pengufile for profile '$Name' not found. Expected $expected"
}

function Test-ContainerExists {
  param([string]$Name)
  & $ENG container inspect $Name *> $null
  return ($LASTEXITCODE -eq 0)
}

function Test-ContainerRunning {
  param([string]$Name)
  # Returns $true if container exists and running.
  & $ENG container inspect -f "{{.State.Running}}" $Name 2>$null | Out-String | ForEach-Object { $_.Trim() } | ForEach-Object {
    return ($_ -eq "true")
  }
  return $false
}

function Stop-Container([string]$Name) {
  if (Test-ContainerExists -Name $Name) {
    & $ENG stop $Name *> $null
  }
}

function Remove-Container([string]$Name) {
  if (-not (Test-ContainerExists -Name $Name)) { return }
  & $ENG rm -f $Name *> $null
  if (Test-ContainerExists -Name $Name) {
    Write-Warning "Unable to remove container $Name"
  }
}

function Remove-Volumes([string[]]$Volumes) {
  & $ENG volume rm -f @($Volumes) *> $null
}

function Build([string]$Image, [string]$ProfileSafe) {
  $pengufile = Resolve-PenguFile -Name $ProfileSafe
  & $ENG build -t $Image -f $pengufile --build-arg UID=$Uid --build-arg GID=$Gid --build-arg USERNAME=pengu . | Out-Null
}

function CreateIfNeeded([string]$Container, [string]$Image, [string]$HomeVol, [string]$AptVol, [string]$ListsVol) {
  if (-not (Test-ContainerExists -Name $Container)) {
    & $ENG create --name $Container `
      -v "$HostPath:/workspace$WorkspaceSuffix" `
      -v "$HomeVol:/home/pengu" `
      -v "$AptVol:/var/cache/apt" `
      -v "$ListsVol:/var/lib/apt/lists" `
      $Image tail -f /dev/null | Out-Null
  }
}

function Ensure-Running([string]$ProfileRaw) {
  $profileSafe = Slugify $ProfileRaw

  $image     = "pengu:$ProjectSafe-$profileSafe"
  $container = "$ProjectSafe-pengu-$profileSafe"
  $homeVol   = "$ProjectSafe-pengu-$profileSafe-home"
  $aptVol    = "$ProjectSafe-pengu-$profileSafe-apt"
  $listsVol  = "$ProjectSafe-pengu-$profileSafe-lists"

  if (-not (Test-ContainerExists -Name $container)) {
    Build -Image $image -ProfileSafe $profileSafe
    CreateIfNeeded -Container $container -Image $image -HomeVol $homeVol -AptVol $aptVol -ListsVol $listsVol
  }

  if (-not (Test-ContainerRunning -Name $container)) {
    & $ENG start $container *> $null
  }

  return @{
    ProfileSafe = $profileSafe
    Image       = $image
    Container   = $container
    HomeVol     = $homeVol
    AptVol      = $aptVol
    ListsVol    = $listsVol
  }
}

function Show-Help {
@"
Pengu - Your persistent Linux buddy (Windows)

USAGE:
  .\pengu.ps1 COMMAND [PROFILE]
  # PROFILE defaults to 'default'

COMMANDS:
  up       Start Pengu container (builds if needed)
           - Creates a new Linux environment for this project/profile
           - Builds the image from the selected Pengufile if it doesn't exist
           - Starts the container with persistent volumes

  shell    Enter Pengu shell as regular user
           - Opens an interactive bash session
           - Your project folder is mounted at /workspace
           - Starts the container automatically if needed

  root     Enter Pengu shell as root user
           - Same as shell but with root privileges

  stop     Stop the Pengu container for the selected profile

  rm       Remove the Pengu container for the selected profile (keeps volumes)

  rebuild  Rebuild and restart Pengu container for the selected profile

  commit   Save current container state to image (requires container to exist)

  nuke     Complete removal (container + all volumes) for the selected profile

  profile list              List local profiles (.pengu/Pengufile.*)
  profile available         Show profiles available from repository
  profile install <name>    Download and install a profile

  help     Show this help message

EXAMPLES:
  .\pengu.ps1 up; .\pengu.ps1 shell
  .\pengu.ps1 up rust; .\pengu.ps1 shell rust
  .\pengu.ps1 profile list
  .\pengu.ps1 profile install rust

NOTES:
  - Pengu build definitions live in .pengu/Pengufile (default) and .pengu/Pengufile.<profile>
  - On Podman, the workspace mount uses ':U' to avoid permission issues when writing to /workspace

PROJECT: $ProjectRaw (normalized: $ProjectSafe)
ENGINE:  $ENG
"@
}

function ProfileList {
  $base = ".pengu"
  $found = $false

  $defaultPath = Join-Path $base "Pengufile"
  if (Test-Path $defaultPath -PathType Leaf) {
    Write-Host "default ($defaultPath)"
    $found = $true
  }

  Get-ChildItem -Path $base -Filter "Pengufile.*" -ErrorAction SilentlyContinue | ForEach-Object {
    $name = $_.Name -replace "^Pengufile\.", ""
    Write-Host "$name ($($_.FullName))"
    $found = $true
  }

  if (-not $found) {
    Write-Host "No profiles found. Use '.\pengu.ps1 profile install <name>' to download one."
  }
}

function ProfileAvailable {
  Write-Host "Fetching available profiles..."
  $url = "https://raw.githubusercontent.com/soyrochus/pengu/main/profiles/profiles.txt"

  try {
    $resp = Invoke-WebRequest -UseBasicParsing -Uri $url -ErrorAction Stop
    Write-Host $resp.Content
  } catch {
    Write-Host "Error: Failed to fetch profiles from server."
    Write-Host $_.Exception.Message
    exit 1
  }
}

function ProfileInstall {
  param([string]$Name)

  if ([string]::IsNullOrWhiteSpace($Name)) {
    Write-Host "Usage: .\pengu.ps1 profile install <name>"
    Write-Host "Example: .\pengu.ps1 profile install rust"
    exit 1
  }

  $dst = Join-Path ".pengu" ("Pengufile.{0}" -f $Name)

  if (Test-Path $dst -PathType Leaf) {
    $ans = Read-Host "Profile '$Name' already exists. Overwrite? [y/N]"
    if ($ans -notmatch "^(y|Y|yes)$") {
      Write-Host "Cancelled."
      return
    }
  }

  Write-Host "Installing profile '$Name'..."
  $url = "https://raw.githubusercontent.com/soyrochus/pengu/main/profiles/$Name/Dockerfile"

  New-Item -ItemType Directory -Force -Path ".pengu" | Out-Null

  try {
    Invoke-WebRequest -UseBasicParsing -Uri $url -OutFile $dst -ErrorAction Stop
    Write-Host "✓ Profile '$Name' installed to $dst"
  } catch {
    if (Test-Path $dst) { Remove-Item $dst -Force }
    Write-Host "Error: Profile '$Name' not found on server or download failed."
    exit 1
  }
}

if (-not $Cmd) {
  Write-Host "Usage: .\pengu.ps1 {up|shell|root|stop|rm|rebuild|commit|nuke|profile|help} [PROFILE]"
  Write-Host "Try '.\pengu.ps1 help' for more information."
  exit 1
}

switch ($Cmd) {
  "help" { Show-Help; break }

  "profile" {
    # Windows-only: interpret subcommands from $Rest
    # Usage:
    #   .\pengu.ps1 profile list
    #   .\pengu.ps1 profile available
    #   .\pengu.ps1 profile install <name>
    $sub = if ($Rest.Length -ge 1) { $Rest[0] } else { "" }
    $name = if ($Rest.Length -ge 2) { $Rest[1] } else { "" }

    switch ($sub) {
      "list"      { ProfileList }
      "available" { ProfileAvailable }
      "install"   { ProfileInstall -Name $name }
      default     { Write-Host "Usage: .\pengu.ps1 profile {list|available|install <name>}" }
    }
    break
  }

  "up" {
    $ctx = Ensure-Running -ProfileRaw $Profile
    Write-Host "Pengu up → .\pengu.ps1 shell $($Profile)"
    break
  }

  "shell" {
    $ctx = Ensure-Running -ProfileRaw $Profile
    & $ENG exec -it $ctx.Container bash
    break
  }

  "root" {
    $ctx = Ensure-Running -ProfileRaw $Profile
    & $ENG exec -it --user 0 $ctx.Container bash
    break
  }

  "stop" {
    $profileSafe = Slugify $Profile
    $container = "$ProjectSafe-pengu-$profileSafe"
    Stop-Container -Name $container
    break
  }

  "rm" {
    $profileSafe = Slugify $Profile
    $container = "$ProjectSafe-pengu-$profileSafe"
    Remove-Container -Name $container
    break
  }

  "rebuild" {
    $profileSafe = Slugify $Profile
    $image     = "pengu:$ProjectSafe-$profileSafe"
    $container = "$ProjectSafe-pengu-$profileSafe"
    $homeVol   = "$ProjectSafe-pengu-$profileSafe-home"
    $aptVol    = "$ProjectSafe-pengu-$profileSafe-apt"
    $listsVol  = "$ProjectSafe-pengu-$profileSafe-lists"

    Remove-Container -Name $container
    Build -Image $image -ProfileSafe $profileSafe
    CreateIfNeeded -Container $container -Image $image -HomeVol $homeVol -AptVol $aptVol -ListsVol $listsVol
    & $ENG start $container *> $null
    break
  }

  "commit" {
    $profileSafe = Slugify $Profile
    $image     = "pengu:$ProjectSafe-$profileSafe"
    $container = "$ProjectSafe-pengu-$profileSafe"

    if (-not (Test-ContainerExists -Name $container)) {
      Write-Host "Error: cannot commit. Container '$container' does not exist." -ForegroundColor Red
      Write-Host "Run: .\pengu.ps1 up $Profile"
      exit 1
    }

    & $ENG commit $container $image | Out-Null
    Write-Host "Committed → $image"
    break
  }

  "nuke" {
    $profileSafe = Slugify $Profile
    $image     = "pengu:$ProjectSafe-$profileSafe"
    $container = "$ProjectSafe-pengu-$profileSafe"
    $homeVol   = "$ProjectSafe-pengu-$profileSafe-home"
    $aptVol    = "$ProjectSafe-pengu-$profileSafe-apt"
    $listsVol  = "$ProjectSafe-pengu-$profileSafe-lists"

    Stop-Container -Name $container
    Remove-Container -Name $container
    Remove-Volumes -Volumes @($homeVol, $aptVol, $listsVol)
    break
  }

  default {
    Write-Host "Error: Unknown command '$Cmd'" -ForegroundColor Red
    Write-Host "Try '.\pengu.ps1 help' for available commands."
    exit 1
  }
}

