param(
    [Parameter(Mandatory = $true, Position = 0)]
    [ValidateSet("vector_academy", "exitexam")]
    [string]$Flavor,

    [Parameter(Mandatory = $true, Position = 1)]
    [ValidateSet("apk", "appbundle", "ios", "ipa")]
    [string]$Target
)

$projectRoot = Split-Path -Parent $PSScriptRoot
Set-Location $projectRoot

$commonArgs = @("--flavor", $Flavor, "--dart-define=FLAVOR=$Flavor")

switch ($Target) {
    "apk" { & flutter build apk @commonArgs --release }
    "appbundle" { & flutter build appbundle @commonArgs --release }
    "ios" { & flutter build ios @commonArgs --release }
    "ipa" { & flutter build ipa @commonArgs --release }
}
