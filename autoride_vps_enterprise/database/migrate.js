import mysql from 'mysql2/promise';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { config } from '../config/env.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

async function runMigration() {
  console.log('[Migration] Connecting to MySQL server at', config.db.host);

  // First connect without specifying database to ensure DB exists
  const connection = await mysql.createConnection({
    host: config.db.host,
    port: config.db.port,
    user: config.db.user,
    password: config.db.password,
    multipleStatements: true,
  });

  try {
    console.log(`[Migration] Ensuring database '${config.db.database}' exists...`);
    await connection.query(
      `CREATE DATABASE IF NOT EXISTS \`${config.db.database}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;`
    );

    console.log(`[Migration] Switching to database '${config.db.database}'...`);
    await connection.changeUser({ database: config.db.database });

    const schemaPath = path.resolve(__dirname, 'schema.sql');
    const sql = fs.readFileSync(schemaPath, 'utf8');

    console.log('[Migration] Executing schema.sql statements...');
    await connection.query(sql);

    console.log('✅ [Migration Completed Successfully!] All tables, initial plans, and gateway configs ready.');
  } catch (error) {
    console.error('❌ [Migration Failed]:', error.message);
    process.exit(1);
  } finally {
    await connection.end();
  }
}

runMigration();
