#!/usr/bin/env pwsh
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$H2_Jar = Join-Path $ScriptDir "..\jar\h2-1.3.175.jar"
$Src = Join-Path $ScriptDir "..\src\OpensmeBackup.java"

if ($env:JAVA_HOME) {
	$JavacCmd = Join-Path $env:JAVA_HOME "bin\javac.exe"
} else {
	$JavacCmd = "javac"
}

if (-not (Get-Command $JavacCmd -ErrorAction SilentlyContinue)) {
	Write-Error "'javac' not found in PATH or via JAVA_HOME."
	Write-Host "Set the JAVA_HOME environment variable and run again."
	Write-Host 'Eg. $env:JAVA_HOME="C:\Program Files\Amazon Corretto\jdk21" ; .\compile.ps1'
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
