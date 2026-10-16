<#
Copies the addon's sources into CS2's addon content folder and compiles them (layout + CSS, textures, particles).
Upload afterwards with the Workshop Tools.

    .\build.ps1
    .\build.ps1 -Cs2Dir "D:\SteamLibrary\steamapps\common\Counter-Strike Global Offensive" -Addon my_addon
#>
param(
	[string]$Cs2Dir = "C:\Program Files (x86)\Steam\steamapps\common\Counter-Strike Global Offensive",
	[string]$Addon = "z4lab_custom_ui"
)
$ErrorActionPreference = "Stop"

$compiler = Join-Path $Cs2Dir "game\bin\win64\resourcecompiler.exe"
$content = Join-Path $Cs2Dir "content\csgo_addons\$Addon"
$game = Join-Path $Cs2Dir "game\csgo_addons\$Addon"

if (-not (Test-Path $compiler)) {
	Write-Error "resourcecompiler.exe not found in $Cs2Dir\game\bin\win64 - set -Cs2Dir, install the CS2 Workshop Tools"
}
if (-not (Test-Path $content)) {
	Write-Error "$content doesn't exist - create the addon '$Addon' in the Workshop Tools first (or set -Addon)"
}

# Sources into the addon's content folder
foreach ($dir in "panorama", "materials", "particles") {
	Copy-Item (Join-Path $PSScriptRoot $dir) $content -Recurse -Force
}
Write-Host "Copied panorama\, materials\, particles\ to $content"

# Compile: the layouts (each pulls in its CSS), then textures, then particles (they reference the textures)
$sources = @(
	Get-ChildItem (Join-Path $content "panorama\layout") -Recurse -Filter *.xml | Sort-Object FullName
	Get-ChildItem (Join-Path $content "materials") -Recurse -Filter *.vtex | Sort-Object FullName
	Get-ChildItem (Join-Path $content "particles") -Recurse -Filter *.vpcf | Sort-Object FullName
)
$failed = $false
foreach ($source in $sources) {
	Write-Host "- $($source.FullName.Substring($content.Length + 1))"
	$output = & $compiler -nop4 -i $source.FullName 2>&1
	if ($LASTEXITCODE -ne 0) {
		$output | Where-Object { $_ -notmatch "^Creating render device" } | ForEach-Object { Write-Host $_ -ForegroundColor Red }
		Write-Host "FAILED: $($source.Name)" -ForegroundColor Red
		$failed = $true
	}
}

if ($failed) {
	Write-Host "Build failed - see the errors above" -ForegroundColor Red
	exit 1
}
Write-Host "Done: compiled files are in $game - upload with the Workshop Tools" -ForegroundColor Green
