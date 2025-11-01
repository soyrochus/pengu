# Pengu - Persistent Linux environment in a container
# Copyright (c) 2025, Iwan van der Kleijn | MIT License
# https://github.com/soyrochus/pengu

Param(
  [Parameter(Mandatory=$false)]
  [ValidateSet("up","shell","root","stop","rm","rebuild","commit","nuke","help")]
  [string]$Cmd = ""
)

function Get-Engine {
  if (Get-Command podman -ErrorAction SilentlyContinue) { return "podman" }
  elseif (Get-Command docker -ErrorAction SilentlyContinue) { return "docker" }
  else { throw "Need podman or docker in PATH." }
}

$ENG = Get-Engine
$Project = if ($env:PROJECT_NAME) { $env:PROJECT_NAME } else { Split-Path -Leaf (Get-Location) }
$Image = "pengu:$Project"
$Container = "$Project-pengu"
$HomeVol = "$Project-pengu-home"
$AptVol = "$Project-pengu-apt"
$ListsVol = "$Project-pengu-lists"
$Uid = if ($env:PENGU_UID) { [int]$env:PENGU_UID } else { 1000 }
$Gid = if ($env:PENGU_GID) { [int]$env:PENGU_GID } else { 1000 }
$SelinuxSuffix = if ($ENG -eq "podman") { ":Z" } else { "" }

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
  .\pengu.ps1 [COMMAND]

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

  help     Show this help message

EXAMPLES:
  .\pengu.ps1 up; .\pengu.ps1 shell    # Start and enter Pengu
  .\pengu.ps1 root                     # Enter as root to install packages
  .\pengu.ps1 stop; .\pengu.ps1 rm     # Clean stop and remove

PROJECT: $Project
ENGINE:  $ENG

For more info: https://github.com/soyrochus/pengu
"@
}

function Build {
  & $ENG build -t $Image --build-arg UID=$Uid --build-arg GID=$Gid --build-arg USERNAME=pengu .
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

if (-not $Cmd) {
  Write-Host "Usage: .\pengu.ps1 {up|shell|root|stop|rm|rebuild|commit|nuke}"
  Write-Host "Try '.\pengu.ps1 help' for more information."
  exit 1
}

switch ($Cmd) {
  "up"      { Build; CreateIfNeeded; & $ENG start $Container; Write-Host "Pengu up → .\pengu.ps1 shell" }
  "shell"   { & $ENG exec -it $Container bash; if ($LASTEXITCODE -ne 0) { & $PSCommandPath up; & $ENG exec -it $Container bash } }
  "root"    { & $ENG exec -it --user 0 $Container bash; if ($LASTEXITCODE -ne 0) { & $PSCommandPath up; & $ENG exec -it --user 0 $Container bash } }
  "stop"    { Stop-Container }
  "rm"      { Remove-Container }
  "rebuild" { Remove-Container; Build; CreateIfNeeded; & $ENG start $Container }
  "commit"  { & $ENG commit $Container $Image | Out-Null; Write-Host "Committed → $Image" }
  "nuke"    { Stop-Container; Remove-Container; Remove-Volumes }
  "help"    { Show-Help }
  default   { 
    Write-Host "Error: Unknown command '$Cmd'" -ForegroundColor Red
    Write-Host "Try '.\pengu.ps1 help' for available commands."
    exit 1
  }
}
