#!/usr/bin/env pwsh
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$H2_Jar = Join-Path $ScriptDir "..\jar\h2-1.3.175.jar"
$SrcDir = Join-Path $ScriptDir "..\src"

if ($env:JAVA_HOME) {
	$JavaCmd = Join-Path $env:JAVA_HOME "bin\java.exe"
} else {
	$JavaCmd = "java"
}

if (-not (Get-Command $JavaCmd -ErrorAction SilentlyContinue)) {
	Write-Error "'java' not found in PATH or via JAVA_HOME."
	Write-Host "Set the JAVA_HOME environment variable and run again."
	Write-Host 'Eg. $env:JAVA_HOME="C:\Program Files\Amazon Corretto\jdk21" ; .\run.ps1'
	exit 1
}

if ($args.Count -lt 1) {
	Write-Host "Usage:"
	Write-Host "  .\run.ps1 export [filename.sql [filename.h2.db]]"
	Write-Host "  .\run.ps1 import [filename.sql [filename.h2.db]]"
	exit 1
}

$Mode = $args[0]
$SqlFile = "backup.sql"
$DbFile = Join-Path $ScriptDir "..\db\sme.h2.db"

if ($Mode -ieq "export") {
	if ($args.Count -ge 2) { $SqlFile = $args[1] }
	if ($args.Count -ge 3) { $DbFile = $args[2] }
} elseif ($Mode -ieq "import") {
	if ($args.Count -ge 2) { $SqlFile = $args[1] }
	if ($args.Count -ge 3) { $DbFile = $args[2] }
}

function Validate-DbFile($file) {
	if ($file -notmatch "\.h2\.db$") {
		Write-Error "Error: database file must end with .h2.db"
		exit 1
	}
}

if ($Mode -ieq "export") {
	Validate-DbFile $DbFile
	$output = & $JavaCmd -cp "$SrcDir;$H2_Jar" OpensmeBackup export "$SqlFile" "$DbFile" 2>&1
	if ($LASTEXITCODE -ne 0) {
		Write-Error $output
		if ($output -match "UnsupportedClassVersionError") {
			Write-Host ""
			Write-Host "Java runtime is too old for this class file version."
			Write-Host "Set JAVA_HOME to a newer JDK and run again."
		}
		Write-Error "Error: export failed"
		exit 1
	} else {
		Write-Host "Backup successfully saved to $SqlFile"
	}

} elseif ($Mode -ieq "import") {
	Validate-DbFile $DbFile
	if (-not (Test-Path $SqlFile)) {
		Write-Error "SQL file '$SqlFile' not found."
		exit 1
	}
	if (-not (Test-Path $DbFile)) {
		Write-Error "Database file '$DbFile' not found."
		exit 1
	}
	$BackupCopy = Join-Path $ScriptDir ("backup." + [IO.Path]::GetFileName($DbFile))
	Copy-Item -Path $DbFile -Destination $BackupCopy -Force

	$output = & $JavaCmd -cp "$SrcDir;$H2_Jar" OpensmeBackup import "$SqlFile" "$DbFile" 2>&1
	if ($LASTEXITCODE -ne 0) {
		Write-Error $output
		if ($output -match "UnsupportedClassVersionError") {
			Write-Host ""
			Write-Host "Java runtime is too old for this class file version."
			Write-Host "Set JAVA_HOME to a newer JDK and run again."
		}
		Write-Host "Import failed. Restoring original database from '$BackupCopy'..."
		Copy-Item -Path $BackupCopy -Destination $DbFile -Force
		Write-Host "Database restored to original state: '$DbFile'"
		exit 1
	} else {
		Remove-Item $BackupCopy -Force
		Write-Host "SQL import completed successfully."
	}
} else {
	Write-Error "Unknown mode '$Mode'"
	exit 1
}
