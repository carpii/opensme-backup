#!/bin/bash
OVERRIDE_JAVAPATH=1
JAVAPATH="/usr/lib/jvm/java-21-amazon-corretto/bin"
H2_JAR="jar/h2-1.3.175.jar"

usage() {
	echo "Usage:"
	echo "  $0 export [dbfile]"
	echo "  $0 import [sqlfile] [dbfile]"
	exit 1
}

if [[ "${OVERRIDE_JAVAPATH}" -eq 1 ]]; then
	JAVA_CMD="${JAVAPATH}/java"
else
	JAVA_CMD="java"
fi

if ! command -v "${JAVA_CMD}" >/dev/null 2>&1; then
	echo "Error: '${JAVA_CMD}' not found or not executable."
	exit 1
fi

if [[ $# -lt 1 ]]; then
	usage
fi

MODE="$1"
shift

validate_dbfile() {
	if [[ ! "$1" =~ \.h2\.db$ ]]; then
		echo "Error: database file must end with .h2.db"
		exit 1
	fi
}

if [[ "${MODE}" == "export" ]]; then
	DBFILE="${1:-./sme.h2.db}"
	validate_dbfile "${DBFILE}"

	"${JAVA_CMD}" -cp .:"${H2_JAR}" OpensmeBackup export "${DBFILE}"
	if [[ $? -ne 0 ]]; then
		echo "Error: export failed"
		exit 1
	fi

elif [[ "${MODE}" == "import" ]]; then
	SQLFILE="${1:-backup.sql}"
	DBFILE="${2:-./sme.h2.db}"
	validate_dbfile "${DBFILE}"

	if [[ ! -f "${SQLFILE}" ]]; then
		echo "Error: SQL file '${SQLFILE}' not found."
		exit 1
	fi

	if [[ ! -f "${DBFILE}" ]]; then
		echo "Error: database file '${DBFILE}' not found."
		exit 1
	fi

	BASENAME=$(basename "${DBFILE}")
	BACKUP_COPY="./backup.${BASENAME}"
	cp -p "${DBFILE}" "${BACKUP_COPY}"

	"${JAVA_CMD}" -cp .:"${H2_JAR}" OpensmeBackup import "${SQLFILE}" "${DBFILE}"
	RESULT=$?

	if [[ $RESULT -ne 0 ]]; then
		echo "Import failed. Restoring original database from '${BACKUP_COPY}'..."
		cp -p "${BACKUP_COPY}" "${DBFILE}"
		echo "Database restored to original state: '${DBFILE}'"
		exit 1
	else
		rm -f "${BACKUP_COPY}"
	fi

else
	echo "Error: unknown mode '${MODE}'"
	usage
fi
