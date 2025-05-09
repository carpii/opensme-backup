#!/usr/bin/env pwsh
$OverrideJavaPath = $true
$JavaPath = "C:\Program Files\Amazon Corretto\jdk21\bin"
$H2_Jar = "jar\h2-1.3.175.jar"
$Src = "OpensmeBackup.java"

if ($OverrideJavaPath) {
	$JavacCmd = Join-Path $JavaPath "javac.exe"
} else {
	$JavacCmd = "javac"
}

if (-not (Get-Command $JavacCmd -ErrorAction SilentlyContinue)) {
	Write-Error "'$JavacCmd' not found or not executable."
	exit 1
}

if (-not (Test-Path $Src)) {
	Write-Error "Source file '$Src' not found."
	exit 1
}

& $JavacCmd -cp "$H2_Jar" "$Src"
if ($LASTEXITCODE -ne 0) {
	Write-Error "Compilation failed."
	exit 1
}

Write-Host "Compiled $Src successfully."
