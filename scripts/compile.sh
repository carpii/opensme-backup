#!/bin/sh
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
H2_JAR="$SCRIPT_DIR/../jar/h2-1.3.175.jar"
SRC="$SCRIPT_DIR/../src/OpensmeBackup.java"

if [ -n "$JAVA_HOME" ]; then
	JAVAC_CMD="$JAVA_HOME/bin/javac"
else
	JAVAC_CMD="javac"
fi

if ! command -v "${JAVAC_CMD}" >/dev/null 2>&1; then
	echo "Error: 'javac' not found."
	echo "Set the JAVA_HOME environment variable and run again."
	echo 'Eg. JAVA_HOME=/usr/lib/jvm/java-21-amazon-corretto ./compile.sh'
	exit 1
fi

if [ ! -f "${SRC}" ]; then
	echo "Error: source file '${SRC}' not found."
	exit 1
fi

"${JAVAC_CMD}" -cp "${H2_JAR}" "${SRC}"
if [ $? -ne 0 ]; then
	echo "Compilation failed."
	exit 1
fi

echo "Compiled ${SRC} successfully."
