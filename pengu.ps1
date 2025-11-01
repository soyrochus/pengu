# Pengu - Persistent Linux environment in a container
# Copyright (c) 2025, Iwan van der Kleijn | MIT License
# https://github.com/soyrochus/pengu

Param(
  [Parameter(Mandatory=$true)]
  [ValidateSet("up","shell","root","stop","rm","rebuild","commit","nuke")]
  [string]$Cmd
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

switch ($Cmd) {
  "up"      { Build; CreateIfNeeded; & $ENG start $Container; Write-Host "Pengu up → .\pengu.ps1 shell" }
  "shell"   { & $ENG exec -it $Container bash; if ($LASTEXITCODE -ne 0) { & $PSCommandPath up; & $ENG exec -it $Container bash } }
  "root"    { & $ENG exec -it --user 0 $Container bash; if ($LASTEXITCODE -ne 0) { & $PSCommandPath up; & $ENG exec -it --user 0 $Container bash } }
  "stop"    { & $ENG stop $Container | Out-Null }
  "rm"      { & $ENG rm -f $Container | Out-Null }
  "rebuild" { & $ENG rm -f $Container | Out-Null; Build; CreateIfNeeded; & $ENG start $Container }
  "commit"  { & $ENG commit $Container $Image | Out-Null; Write-Host "Committed → $Image" }
  "nuke"    { & $ENG rm -f $Container | Out-Null; & $ENG volume rm -f $HomeVol $AptVol $ListsVol | Out-Null }
}
