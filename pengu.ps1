# Pengu - Persistent Linux environment in a container
# Copyright (c) 2025, Iwan van der Kleijn | MIT License
# https://github.com/soyrochus/pengu

Param(
  [Parameter(Mandatory=$false, Position=0)]
  [ValidateSet("up","shell","root","stop","rm","rebuild","commit","nuke","profile","help")]
  [string]$Cmd = "",
  [Parameter(Mandatory=$false, Position=1)]
  [string]$Profile = "default"
)

function Get-Engine {
  if (Get-Command podman -ErrorAction SilentlyContinue) { return "podman" }
  elseif (Get-Command docker -ErrorAction SilentlyContinue) { return "docker" }
  else { throw "Need podman or docker in PATH." }
}

$ENG = Get-Engine
$Project = if ($env:PROJECT_NAME) { $env:PROJECT_NAME } else { Split-Path -Leaf (Get-Location) }
$Image = "pengu:$Project-$Profile"
$Container = "$Project-pengu-$Profile"
$HomeVol = "$Project-pengu-$Profile-home"
$AptVol = "$Project-pengu-$Profile-apt"
$ListsVol = "$Project-pengu-$Profile-lists"
$Uid = if ($env:PENGU_UID) { [int]$env:PENGU_UID } else { 1000 }
$Gid = if ($env:PENGU_GID) { [int]$env:PENGU_GID } else { 1000 }
$SelinuxSuffix = if ($ENG -eq "podman") { ":Z" } else { "" }

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
  }
  else {
    $path = Join-Path $base ("Pengufile.{0}" -f $Name)
    if (Test-Path $path -PathType Leaf) { return $path }
  }

  $expected = if ($Name -eq "default") { "$base/Pengufile" } else { "$base/Pengufile.$Name" }
  throw "Pengufile for profile '$Name' not found. Expected $expected"
}

function Test-ContainerExists {
  param([string]$Name)
  if ($ENG -eq "podman") {
    & $ENG container exists $Name > $null 2>&1
  }
  else {
    & $ENG container inspect $Name > $null 2>&1
  }
  return ($LASTEXITCODE -eq 0)
}

function Stop-Container {
  if (Test-ContainerExists -Name $Container) {
    & $ENG stop $Container > $null 2>&1
  }
}

function Remove-Container {
  if (-not (Test-ContainerExists -Name $Container)) { return }

  if ($ENG -eq "podman") {
    & $ENG rm -f $Container > $null 2>&1
    if ($LASTEXITCODE -ne 0) {
      & $ENG container rm -f $Container > $null 2>&1
    }
  }
  else {
    & $ENG rm -f $Container > $null 2>&1
    if ($LASTEXITCODE -ne 0) {
      & $ENG container rm -f $Container > $null 2>&1
    }
  }

  if (Test-ContainerExists -Name $Container) {
    Write-Warning "Unable to remove container $Container"
  }
}

function Remove-Volumes {
  & $ENG volume rm -f $HomeVol $AptVol $ListsVol > $null 2>&1
}

function Show-Help {
@"
Pengu - Your persistent Linux buddy

USAGE:
  .\pengu.ps1 COMMAND [PROFILE]
  # PROFILE defaults to 'default'

COMMANDS:
  up       Start Pengu container (builds if needed)
           - Creates a new Ubuntu environment for this project
           - Builds the Docker image if it doesn't exist
           - Starts the container with persistent volumes

  shell    Enter Pengu shell as regular user
           - Opens an interactive bash session
           - Your project folder is mounted at /workspace
           - If container isn't running, starts it automatically

  root     Enter Pengu shell as root user
           - Same as shell but with root privileges
           - Useful for installing system packages with apt

  stop     Stop the running Pengu container
           - Gracefully stops the container
           - Data in volumes is preserved

  rm       Remove the Pengu container (keeps data)
           - Deletes the container but preserves volumes
           - Use 'up' to recreate container from existing data

  rebuild  Rebuild and restart Pengu container
           - Removes container, rebuilds image, starts fresh
           - Preserves home directory and apt cache

  commit   Save current container state to image
           - Creates a new image with all installed packages
           - Useful for creating custom base images

  nuke     Complete removal (container + all data)
           - ⚠️  DESTRUCTIVE: Removes everything permanently
           - Deletes container and all persistent volumes

  profile list       List local profiles (.pengu/Pengufile.*)
  profile available  Show available profiles from repository
  profile install    Download and install a profile
                     Usage: .\pengu.ps1 profile install <name>

  help     Show this help message

EXAMPLES:
  .\pengu.ps1 up; .\pengu.ps1 shell            # Default profile
  .\pengu.ps1 up java; .\pengu.ps1 shell java  # Named profile
  .\pengu.ps1 root                             # Enter as root
  .\pengu.ps1 stop; .\pengu.ps1 rm             # Clean stop and remove
  .\pengu.ps1 profile available                # See available profiles
  .\pengu.ps1 profile install rust             # Install Rust profile

PROJECT: $Project
PROFILE: $Profile
ENGINE:  $ENG

For more info: https://github.com/soyrochus/pengu
"@
}

function Build {
  $pengufile = Resolve-PenguFile -Name $Profile
  & $ENG build -t $Image -f $pengufile --build-arg UID=$Uid --build-arg GID=$Gid --build-arg USERNAME=pengu .
}
function CreateIfNeeded {
  if (-not (Test-ContainerExists -Name $Container)) {
    & $ENG create --name $Container `
      -v "$(Get-Location):/workspace$SelinuxSuffix" `
      -v "$HomeVol:/home/pengu$SelinuxSuffix" `
      -v "$AptVol:/var/cache/apt$SelinuxSuffix" `
      -v "$ListsVol:/var/lib/apt/lists$SelinuxSuffix" `
      $Image tail -f /dev/null | Out-Null
  }
}

function ProfileList {
  $base = ".pengu"
  $found = $false
  
  if (Test-Path (Join-Path $base "Pengufile") -PathType Leaf) {
    Write-Host "📄 default ($(Join-Path $base 'Pengufile'))"
    $found = $true
  }
  
  Get-ChildItem -Path $base -Filter "Pengufile.*" -ErrorAction SilentlyContinue | ForEach-Object {
    $name = $_.Name -replace "^Pengufile\.", ""
    Write-Host "📄 $name ($_)"
    $found = $true
  }
  
  if (-not $found) {
    Write-Host "No profiles found. Use 'pengu profile install <name>' to download one."
  }
}

function ProfileAvailable {
  Write-Host "Fetching available profiles..."
  $url = "https://raw.githubusercontent.com/soyrochus/pengu/main/profiles/profiles.txt"
  
  try {
    $profiles = Invoke-WebRequest -UseBasicParsing -Uri $url -ErrorAction Stop
    Write-Host $profiles.Content
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
  
  $dst = Join-Path ".pengu" "Pengufile.$Name"
  
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
  "up"      { Build; CreateIfNeeded; & $ENG start $Container; Write-Host "Pengu up → .\pengu.ps1 shell $Profile" }
  "shell"   { & $ENG exec -it $Container bash; if ($LASTEXITCODE -ne 0) { & $PSCommandPath up $Profile; & $ENG exec -it $Container bash } }
  "root"    { & $ENG exec -it --user 0 $Container bash; if ($LASTEXITCODE -ne 0) { & $PSCommandPath up $Profile; & $ENG exec -it --user 0 $Container bash } }
  "stop"    { Stop-Container }
  "rm"      { Remove-Container }
  "rebuild" { Remove-Container; Build; CreateIfNeeded; & $ENG start $Container }
  "commit"  { & $ENG commit $Container $Image | Out-Null; Write-Host "Committed → $Image" }
  "nuke"    { Stop-Container; Remove-Container; Remove-Volumes }
  "profile" {
    switch ($Profile) {
      "list"      { ProfileList }
      "available" { ProfileAvailable }
      "install"   { ProfileInstall -Name @($args)[1] }
      default     { Write-Host "Usage: .\pengu.ps1 profile {list|available|install <name>}" }
    }
  }
  "help"    { Show-Help }
  default   { 
    Write-Host "Error: Unknown command '$Cmd'" -ForegroundColor Red
    Write-Host "Try '.\pengu.ps1 help' for available commands."
    exit 1
  }
}
