import mysql from 'mysql2/promise';
import { config } from './env.js';

let _pool = null;

export function getDatabasePool() {
  if (!_pool) {
    _pool = mysql.createPool({
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
  }
  return _pool;
}

export const pool = getDatabasePool();

export async function query(sql, params = []) {
  const db = getDatabasePool();
  try {
    const [rows] = await db.query(sql, params);
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
    console.warn(`[Database Warning] MySQL connection warning: ${error.message}`);
    return false;
  }
}

export async function testDbConnection() {
  return testConnection();
}
