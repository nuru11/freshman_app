param(
    [Parameter(Mandatory = $true, Position = 0)]
    [ValidateSet("vector_academy", "exitexam")]
    [string]$Flavor,

    [Parameter(Position = 1)]
    [string[]]$DeviceArgs
)

$projectRoot = Split-Path -Parent $PSScriptRoot
Set-Location $projectRoot

$flutterArgs = @(
    "run",
    "--flavor", $Flavor,
    "--dart-define=FLAVOR=$Flavor"
) + $DeviceArgs

& flutter @flutterArgs
