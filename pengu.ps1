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
  & $ENG build -t $Image --build-arg UID=1000 --build-arg GID=1000 --build-arg USERNAME=pengu .
}
function CreateIfNeeded {
  & $ENG container exists $Container | Out-Null
  if ($LASTEXITCODE -ne 0) {
    & $ENG create --name $Container `
      -v "$(Get-Location):/workspace:Z" `
      -v "$HomeVol:/home/pengu:Z" `
      -v "$AptVol:/var/cache/apt:Z" `
      -v "$ListsVol:/var/lib/apt/lists:Z" `
      $Image tail -f /dev/null | Out-Null
  }
}

if (-not $Cmd) {
  Write-Host "Usage: .\pengu.ps1 [COMMAND]"
  Write-Host "Try '.\pengu.ps1 help' for more information."
  exit 1
}

switch ($Cmd) {
  "up"      { Build; CreateIfNeeded; & $ENG start $Container; Write-Host "Pengu up → .\pengu.ps1 shell" }
  "shell"   { & $ENG exec -it $Container bash; if ($LASTEXITCODE -ne 0) { & $PSCommandPath up; & $ENG exec -it $Container bash } }
  "root"    { & $ENG exec -it --user 0 $Container bash; if ($LASTEXITCODE -ne 0) { & $PSCommandPath up; & $ENG exec -it --user 0 $Container bash } }
  "stop"    { & $ENG stop $Container | Out-Null }
  "rm"      { & $ENG rm -f $Container | Out-Null }
  "rebuild" { & $ENG rm -f $Container | Out-Null; Build; CreateIfNeeded; & $ENG start $Container }
  "commit"  { & $ENG commit $Container $Image | Out-Null; Write-Host "Committed → $Image" }
  "nuke"    { & $ENG rm -f $Container | Out-Null; & $ENG volume rm -f $HomeVol $AptVol $ListsVol | Out-Null }
  "help"    { Show-Help }
  default   { 
    Write-Host "Error: Unknown command '$Cmd'" -ForegroundColor Red
    Write-Host "Try '.\pengu.ps1 help' for available commands."
    exit 1
  }
}
