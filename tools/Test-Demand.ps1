[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$GodotExecutable,
    [string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot)
)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$runtime = Join-Path $ProjectRoot ('release/demand-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $runtime | Out-Null
Get-ChildItem -LiteralPath (Join-Path $ProjectRoot 'tests/demand') -File | Copy-Item -Destination $runtime
foreach ($source in @('scripts/global/smart_window_data.gd','scripts/global/distribution_modes.gd')) {
    Copy-Item -LiteralPath (Join-Path $ProjectRoot $source) -Destination $runtime
}
# The two stub class names are fixed. Seed only their project-local cache
# instead of launching the editor and modifying the user's editor settings.
$cache = Join-Path $runtime '.godot'
New-Item -ItemType Directory -Path $cache | Out-Null
Copy-Item -LiteralPath (Join-Path $runtime 'global_script_class_cache.cfg') -Destination $cache
$log = Join-Path $runtime 'verification.log'
& $GodotExecutable --headless --path $runtime --log-file $log --script res://verify_demand.gd
if ($LASTEXITCODE -ne 0) { throw "Demand verification failed. Log: $log" }
if (-not (Select-String -LiteralPath $log -Pattern '^ASM DEMAND: \d+ checks, 0 failures$' -Quiet)) {
    throw "Demand success summary missing. Log: $log"
}
if (Select-String -LiteralPath $log -Pattern '^SCRIPT ERROR:|^ERROR:' -Quiet) {
    throw "Godot reported an error. Log: $log"
}
Write-Output "Verified demand log: $log"
