#!/bin/sh
OVERRIDE_JAVAPATH=1
JAVAPATH="/usr/lib/jvm/java-21-amazon-corretto/bin"
H2_JAR="jar/h2-1.3.175.jar"
SRC="OpensmeBackup.java"

if [ "${OVERRIDE_JAVAPATH}" -eq 1 ]; then
	JAVAC_CMD="${JAVAPATH}/javac"
else
	JAVAC_CMD="javac"
fi

if ! command -v "${JAVAC_CMD}" >/dev/null 2>&1; then
	echo "Error: '${JAVAC_CMD}' not found or not executable."
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
