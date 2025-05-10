import java.io.File;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.Statement;

public class OpensmeBackup {
	public static void main(String[] args) {
		if (args.length < 1 || !(args[0].equals("import") || args[0].equals("export"))) {
			System.err.println("Usage: java OpensmeBackup [import <sql-file> [db-file]] | [export [sql-file] [db-file]]");
			System.exit(1);
		}

		String mode = args[0];
		String sqlFile = "backup.sql";
		String dbFilePath;

		if (mode.equals("export")) {
			sqlFile = (args.length >= 2) ? args[1] : "backup.sql";
			dbFilePath = (args.length >= 3) ? args[2] : "./sme.h2.db";
		} else {
			if (args.length < 2) {
				System.err.println("Error: import requires a SQL file.");
				System.exit(1);
			}
			sqlFile = args[1];
			dbFilePath = (args.length >= 3) ? args[2] : "./sme.h2.db";
		}

		File dbFile = new File(dbFilePath);
		if (!dbFile.exists()) {
			System.err.println("Error: Database file '" + dbFilePath + "' does not exist.");
			System.exit(1);
		}

		if (!dbFilePath.endsWith(".h2.db")) {
			System.err.println("Error: Database file must have .h2.db extension.");
			System.exit(1);
		}

		String basePath = dbFilePath.substring(0, dbFilePath.length() - 6);
		String dbUrl = "jdbc:h2:file:" + basePath;
		String dbUser = "";
		String dbPass = "";

		try (
			Connection conn = DriverManager.getConnection(dbUrl, dbUser, dbPass);
			Statement stmt = conn.createStatement()
		) {
			System.out.println("Connected to H2 database: " + dbFilePath);

			if (mode.equals("export")) {
				stmt.execute("SCRIPT TO '" + sqlFile + "'");
				System.out.println("Exported database to: " + sqlFile);

				File f = new File(sqlFile);
				if (f.exists() && f.length() > 0) {
					System.out.println("Export file verified.");
					System.exit(0);
				} else {
					System.err.println("Export failed: file not created or empty.");
					System.exit(1);
				}
			} else {
				File f = new File(sqlFile);
				if (!f.exists() || f.length() == 0) {
					System.err.println("Import failed: SQL file '" + sqlFile + "' does not exist or is empty.");
					System.exit(1);
				}

				System.out.println("Wiping database...");
				try {
					stmt.execute("DROP ALL OBJECTS");
				} catch (Exception e) {
					System.err.println("Error while dropping objects: " + e.getMessage());
					System.exit(1);
				}

				System.out.println("Importing from SQL file...");
				try {
					stmt.execute("RUNSCRIPT FROM '" + sqlFile + "'");
					System.out.println("SQL import completed successfully.");
					System.exit(0);
				} catch (Exception e) {
					System.err.println("Error while importing SQL file: " + e.getMessage());
					System.exit(1);
				}
			}
		} catch (Exception e) {
			e.printStackTrace();
			System.exit(1);
		}
	}
}
