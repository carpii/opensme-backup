#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
H2_JAR="$SCRIPT_DIR/../jar/h2-1.3.175.jar"
SRC_DIR="$SCRIPT_DIR/../src"

if [ -n "$JAVA_HOME" ]; then
	JAVA_CMD="$JAVA_HOME/bin/java"
else
	JAVA_CMD="java"
fi

if ! command -v "${JAVA_CMD}" >/dev/null 2>&1; then
	echo "Error: 'java' not found."
	echo "Set the JAVA_HOME environment variable and run again."
	echo 'Eg. JAVA_HOME=/usr/lib/jvm/java-21-amazon-corretto ./run.sh'
	exit 1
fi

usage() {
	echo "Usage:"
	echo "  $0 export [filename.sql [filename.h2.db]]"
	echo "  $0 import [filename.sql [filename.h2.db]]"
	exit 1
}

ARGS=("$@")
[[ $# -lt 1 ]] && usage

MODE="${ARGS[0]}"
shift

validate_dbfile() {
	[[ ! "$1" =~ \.h2\.db$ ]] && echo "Error: database file must end with .h2.db" && exit 1
}

DEFAULT_DB="$SCRIPT_DIR/../db/sme.h2.db"

if [[ "$MODE" == "export" ]]; then
	SQLFILE="${1:-backup.sql}"
	DBFILE="${2:-$DEFAULT_DB}"
	validate_dbfile "$DBFILE"

	OUTPUT=$("${JAVA_CMD}" -cp "$SRC_DIR:$H2_JAR" OpensmeBackup export "$SQLFILE" "$DBFILE" 2>&1)
	STATUS=$?

	if [[ $STATUS -ne 0 ]]; then
		echo "$OUTPUT"
		[[ "$OUTPUT" == *"UnsupportedClassVersionError"* ]] && {
			echo -e "\nError: Java runtime is too old for this class file version."
			echo "Set JAVA_HOME to a newer JDK and run again."
		}
		echo "Error: export failed"
		exit 1
	else
		echo "Backup successfully saved to $SQLFILE"
	fi

elif [[ "$MODE" == "import" ]]; then
	SQLFILE="${1:-backup.sql}"
	DBFILE="${2:-$DEFAULT_DB}"
	validate_dbfile "$DBFILE"

	[[ ! -f "$SQLFILE" ]] && echo "Error: SQL file '$SQLFILE' not found." && exit 1
	[[ ! -f "$DBFILE" ]] && echo "Error: database file '$DBFILE' not found." && exit 1

	BACKUP_COPY="$SCRIPT_DIR/backup.$(basename "$DBFILE")"
	cp -p "$DBFILE" "$BACKUP_COPY"

	OUTPUT=$("${JAVA_CMD}" -cp "$SRC_DIR:$H2_JAR" OpensmeBackup import "$SQLFILE" "$DBFILE" 2>&1)
	STATUS=$?

	if [[ $STATUS -ne 0 ]]; then
		echo "$OUTPUT"
		[[ "$OUTPUT" == *"UnsupportedClassVersionError"* ]] && {
			echo -e "\nError: Java runtime is too old for this class file version."
			echo "Set JAVA_HOME to a newer JDK and run again."
		}
		echo "Import failed. Restoring original database from '${BACKUP_COPY}'..."
		cp -p "$BACKUP_COPY" "$DBFILE"
		echo "Database restored to original state: '$DBFILE'"
		exit 1
	else
		rm -f "$BACKUP_COPY"
		echo "SQL import completed successfully."
	fi

else
	echo "Error: unknown mode '${MODE}'"
	usage
fi
