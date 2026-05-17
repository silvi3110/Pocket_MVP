const { Pool } = require('pg');

const pool = new Pool({
  connectionString: process.env.DATABASE_URL || 'postgresql://postgres:postgres@localhost:5432/pocket_card',
});

pool.on('error', (err) => console.error('DB error:', err));

async function query(text, params) {
  return pool.query(text, params);
}

/** Ejecuta callback dentro de BEGIN/COMMIT/ROLLBACK */
async function withTransaction(callback) {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const result = await callback(client);
    await client.query('COMMIT');
    return result;
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
}

module.exports = { pool, query, withTransaction };
