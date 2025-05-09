#!/usr/bin/env pwsh
param(
	[string]$Mode,
	[string]$SqlFile = "backup.sql",
	[string]$DbFile = "./sme.h2.db"
)

$OverrideJavaPath = $true
$JavaPath = "C:\Program Files\Amazon Corretto\jdk21\bin"
$H2_Jar = "jar\h2-1.3.175.jar"

function Show-Usage {
	Write-Host "Usage:"
	Write-Host "  .\run.ps1 export [dbfile]"
	Write-Host "  .\run.ps1 import [sqlfile] [dbfile]"
	exit 1
}

if (-not $Mode) {
	Show-Usage
}

if ($OverrideJavaPath) {
	$JavaCmd = Join-Path $JavaPath "java.exe"
} else {
	$JavaCmd = "java"
}

if (-not (Get-Command $JavaCmd -ErrorAction SilentlyContinue)) {
	Write-Error "'$JavaCmd' not found or not executable."
	exit 1
}

function Validate-DbFile([string]$file) {
	if ($file -notmatch "\.h2\.db$") {
		Write-Error "Error: database file must end with .h2.db"
		exit 1
	}
}

if ($Mode -ieq "export") {
	if ($args.Count -ge 1) {
		$DbFile = $args[0]
	}
	Validate-DbFile $DbFile

	& $JavaCmd -cp ".;$H2_Jar" OpensmeBackup export "$DbFile"
	if ($LASTEXITCODE -ne 0) {
		Write-Error "Error: export failed"
		exit 1
	}

} elseif ($Mode -ieq "import") {
	if ($args.Count -ge 1) {
		$SqlFile = $args[0]
	}
	if ($args.Count -ge 2) {
		$DbFile = $args[1]
	}
	Validate-DbFile $DbFile

	if (-not (Test-Path $SqlFile)) {
		Write-Error "SQL file '$SqlFile' not found."
		exit 1
	}

	if (-not (Test-Path $DbFile)) {
		Write-Error "Database file '$DbFile' not found."
		exit 1
	}

	$BackupCopy = "backup." + [IO.Path]::GetFileName($DbFile)
	Copy-Item -Path $DbFile -Destination $BackupCopy -Force

	& $JavaCmd -cp ".;$H2_Jar" OpensmeBackup import "$SqlFile" "$DbFile"
	if ($LASTEXITCODE -ne 0) {
		Write-Host "Import failed. Restoring original database from '$BackupCopy'..."
		Copy-Item -Path $BackupCopy -Destination $DbFile -Force
		Write-Host "Database restored to original state: '$DbFile'"
		exit 1
	} else {
		Remove-Item $BackupCopy -Force
	}
} else {
	Write-Error "Unknown mode '$Mode'"
	Show-Usage
}
