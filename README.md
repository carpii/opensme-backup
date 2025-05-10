# OpenSME Backup Tool

`opensme-backup` allows you to export your StockMarketEye database to a raw SQL dump  
Likewise it can rebuild your database from a previously dumped `.sql` backup.

The benefit is these backups are portable, and unlike the native StockMarketEye backups, can be used to migrate between operating systems.

---

## Prerequisites

- Java SDK 21 (or newer), with `java` and `javac` binaries
- If Java tools are not in your system `PATH`, set the `JAVA_HOME` environment variable

---

## How to Compile

> You can run the scripts from any directory; they internally resolve required paths.

**macOS / Linux:**

```bash
./scripts/compile.sh
```

**Windows:**

```powershell
.\scripts\compile.ps1
```

---

## Usage

**Exporting the database:**

**macOS / Linux:**

```bash
./scripts/run.sh export [filename.sql [filename.h2.db]]
```

**Windows:**

```powershell
.\scripts\run.ps1 export [filename.sql [filename.h2.db]]
```

**Importing a SQL file into the database:**

**macOS / Linux:**

```bash
./scripts/run.sh import [filename.sql [filename.h2.db]]
```

**Windows:**

```powershell
.\scripts\run.ps1 import [filename.sql [filename.h2.db]]
```

---

## Troubleshooting

### Missing `java` or `javac`

The scripts first check the `JAVA_HOME` environment variable. If it's not set, they fall back to using your system `PATH`.

If neither location provides a valid Java installation, you will see:

```
Error: 'java' or 'javac' not found.
```

Fix this by running with `JAVA_HOME` set:

```bash
JAVA_HOME=/path/to/jdk ./scripts/run.sh export
```

```powershell
$env:JAVA_HOME="C:\Program Files\Amazon Corretto\jdk21"
.\scripts\run.ps1 export
```

---

### Java version mismatch

If your runtime is too old:

```
Error: Java runtime is too old for this class file version.
```

Set `JAVA_HOME` to a newer JDK and re-run the script.
