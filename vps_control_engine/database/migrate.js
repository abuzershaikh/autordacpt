import mysql from 'mysql2/promise';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { config } from '../config/env.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

export async function runMigrations() {
  console.log('[Migration] Checking database connection and schema...');
  let connection = null;

  try {
    // 1. Connect without database name first to ensure database exists
    connection = await mysql.createConnection({
      host: config.db.host,
      port: config.db.port,
      user: config.db.user,
      password: config.db.password,
      multipleStatements: true,
    });

    console.log(`[Migration] Connected to MySQL server at ${config.db.host}:${config.db.port}`);

    // 2. Create database if it does not exist
    await connection.query(`CREATE DATABASE IF NOT EXISTS \`${config.db.database}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;`);
    console.log(`[Migration] Ensured database \`${config.db.database}\` exists.`);

    await connection.query(`USE \`${config.db.database}\`;`);

    // 3. Read and execute schema.sql
    const schemaPath = path.resolve(__dirname, 'schema.sql');
    if (fs.existsSync(schemaPath)) {
      const sqlContent = fs.readFileSync(schemaPath, 'utf8');
      await connection.query(sqlContent);
      console.log('[Migration] ✓ Schema and initial seed data applied successfully!');
    }

    return true;
  } catch (error) {
    console.warn(`[Migration Notice] Database migration could not complete: ${error.message}`);
    console.warn('[Migration Notice] When deploying on VPS with MySQL running, tables will initialize automatically.');
    return false;
  } finally {
    if (connection) {
      await connection.end();
    }
  }
}

// Auto-run if executed directly
if (process.argv[1] === fileURLToPath(import.meta.url)) {
  runMigrations().then(() => process.exit(0));
}
