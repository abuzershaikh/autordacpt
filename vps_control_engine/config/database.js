import mysql from 'mysql2/promise';
import { config } from './env.js';

let pool = null;

export function getDatabasePool() {
  if (!pool) {
    pool = mysql.createPool({
      host: config.db.host,
      port: config.db.port,
      user: config.db.user,
      password: config.db.password,
      database: config.db.database,
      waitForConnections: true,
      connectionLimit: config.db.connectionLimit,
      queueLimit: 0,
      enableKeepAlive: true,
      keepAliveInitialDelay: 10000,
    });

    console.log(`[Database] Initialized MySQL pool for database: ${config.db.database} on ${config.db.host}:${config.db.port}`);
  }
  return pool;
}

export async function query(sql, params = []) {
  const db = getDatabasePool();
  try {
    const [rows, fields] = await db.query(sql, params);
    return rows;
  } catch (error) {
    console.error(`[Database Error] SQL Query Failed: ${sql.substring(0, 100)}...`, error.message);
    throw error;
  }
}

export async function execute(sql, params = []) {
  const db = getDatabasePool();
  try {
    const [result] = await db.execute(sql, params);
    return result;
  } catch (error) {
    console.error(`[Database Error] SQL Execution Failed: ${sql.substring(0, 100)}...`, error.message);
    throw error;
  }
}

export async function testConnection() {
  try {
    const db = getDatabasePool();
    const [result] = await db.query('SELECT 1 + 1 AS solution');
    return result[0]?.solution === 2;
  } catch (error) {
    console.warn(`[Database Warning] Could not connect to MySQL server (${config.db.host}:${config.db.port}): ${error.message}`);
    return false;
  }
}
