const express = require("express");
const cors = require("cors");
const fs = require("fs");
const path = require("path");

const app = express();
const PORT = 3000;

app.use(cors());
app.use(express.json());

const dataFilePath = path.join(__dirname, "data.json");

// Load existing data or create new file
let sharedData = [];

if (fs.existsSync(dataFilePath)) {
  const raw = fs.readFileSync(dataFilePath);
  sharedData = JSON.parse(raw || "[]");
}

// Save to file
function saveToFile() {
  fs.writeFileSync(dataFilePath, JSON.stringify(sharedData, null, 2));
}

// POST: receive name + number, store to file
app.post("/share-location", (req, res) => {
  const { name, number } = req.body;

  if (!name || !number) {
    return res.status(400).json({ message: "Missing name or number" });
  }

  const newEntry = {
    id: Date.now(),
    name,
    number,
    timestamp: new Date().toISOString(),
  };

  sharedData.push(newEntry);
  saveToFile();

  console.log("📥 New entry saved:", newEntry);
  res.status(200).json({ message: "Data shared successfully", data: newEntry });
});

// GET: return data from memory (loaded from file at start)
app.get("/locations", (req, res) => {
  res.status(200).json(sharedData);
});

app.listen(PORT, () => {
  console.log(`🚀 Server running at http://localhost:${PORT}`);
});
