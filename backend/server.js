const express = require('express');
const sqlite3 = require('sqlite3').verbose();
const cors = require('cors');
const path = require('path');

const app = express();
const port = 3000;

app.use(cors());
app.use(express.json({ limit: '50mb' }));

// Initialize SQLite database
const dbPath = path.resolve(__dirname, 'database.sqlite');
const db = new sqlite3.Database(dbPath, (err) => {
  if (err) {
    console.error('Error opening database', err);
  } else {
    console.log('Connected to the SQLite database.');
    
    // Create a generic key-value table for syncing
    db.run(`
      CREATE TABLE IF NOT EXISTS sync_data (
        key TEXT PRIMARY KEY,
        value TEXT,
        updated_at INTEGER
      )
    `);
  }
});

// GET endpoint to retrieve data for a specific key
app.get('/api/sync/:key', (req, res) => {
  const key = req.params.key;
  
  db.get('SELECT value, updated_at FROM sync_data WHERE key = ?', [key], (err, row) => {
    if (err) {
      console.error(err);
      res.status(500).json({ error: 'Internal server error' });
      return;
    }
    
    if (row) {
      res.json(row);
    } else {
      res.status(404).json({ error: 'Key not found' });
    }
  });
});

// POST endpoint to update data for a specific key
app.post('/api/sync/:key', (req, res) => {
  const key = req.params.key;
  const { value, updated_at } = req.body;
  
  if (!value || !updated_at) {
    res.status(400).json({ error: 'Missing value or updated_at' });
    return;
  }
  
  // Last-write-wins simple resolution
  db.get('SELECT updated_at FROM sync_data WHERE key = ?', [key], (err, row) => {
    if (err) {
      res.status(500).json({ error: 'Internal server error' });
      return;
    }
    
    if (row && row.updated_at > updated_at) {
      // Server has newer data, reject update (or just return success but don't update)
      res.json({ success: true, message: 'Server has newer data, update ignored.', newer_on_server: true });
      return;
    }
    
    // Insert or replace
    db.run(
      'INSERT OR REPLACE INTO sync_data (key, value, updated_at) VALUES (?, ?, ?)',
      [key, value, updated_at],
      function(err) {
        if (err) {
          res.status(500).json({ error: 'Internal server error' });
          return;
        }
        res.json({ success: true, message: 'Data synced successfully' });
      }
    );
  });
});

app.listen(port, '0.0.0.0', () => {
  console.log(`Habit Tracker Local Sync Server running on http://0.0.0.0:${port}`);
  console.log(`Point your phone app to your laptop's Local IP Address!`);
});
