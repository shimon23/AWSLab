const express = require("express");
const mysql   = require("mysql2/promise");
const path    = require("path");

const app = express();

// חיבור לבר בדא
const pool = mysql.createPool({
  host: process.env.DB_HOST,
  port: process.env.DB_PORT,
  user: process.env.DB_USER,
  password: process.env.DB_PASS,
  database: process.env.DB_NAME,
});

// 1) Serve קבצים סטטיים מתיקיית public
app.use(express.static(path.join(__dirname, "public")));

// 2) Route חדש ל־/db – בונה טבלה של users
app.get("/db", async (req, res) => {
  try {
    const [rows] = await pool.query(
      "SELECT id, name, last_seen FROM users ORDER BY last_seen DESC LIMIT 20"
    );
    // בנה HTML עם טבלה
    let html = `
      <h1>Users</h1>
      <table border="1" cellpadding="5" cellspacing="0">
        <thead>
          <tr><th>#</th><th>Name</th><th>Last Seen</th></tr>
        </thead>
        <tbody>
    `;
    rows.forEach(r => {
      html += `
        <tr>
          <td>${r.id}</td>
          <td>${r.name}</td>
          <td>${new Date(r.last_seen).toLocaleString()}</td>
        </tr>`;
    });
    html += `
        </tbody>
      </table>
      <p><a href="/">Back</a> · <a href="/db">Refresh</a></p>
    `;
    res.send(html);
  } catch (err) {
    console.error(err);
    res.status(500).send("DB error");
  }
});

// 3) כל שאר ה־routes חוזרים ל־index.html
app.get("*", (req, res) => {
  res.sendFile(path.join(__dirname, "public", "index.html"));
});

// מאזין על פורט 3000
app.listen(3000, () => console.log("App listening on 3000"));
