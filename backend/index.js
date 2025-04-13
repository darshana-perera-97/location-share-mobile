const express = require("express");
const cors = require("cors");
const fs = require("fs");
const path = require("path");

const app = express();
const PORT = 3000;

app.use(cors());
app.use(express.json());

const dataFilePath = path.join(__dirname, "data.json");

// Load saved data from file
let sharedData = [];

if (fs.existsSync(dataFilePath)) {
  const raw = fs.readFileSync(dataFilePath);
  sharedData = JSON.parse(raw || "[]");
}

function saveToFile() {
  fs.writeFileSync(dataFilePath, JSON.stringify(sharedData, null, 2));
}

function generateUserID() {
  return "USR-" + Math.floor(100000 + Math.random() * 900000);
}

// Register user
app.post("/share-location", (req, res) => {
  const { name, number } = req.body;

  if (!name || !number) {
    return res.status(400).json({ message: "Missing name or number" });
  }

  const userId = generateUserID();

  const newEntry = {
    id: userId,
    name,
    number,
    timestamp: new Date().toISOString(),
  };

  sharedData.push(newEntry);
  saveToFile();

  console.log("📥 Registered user:", newEntry);
  res.status(200).json({
    message: "User registered successfully",
    data: newEntry,
  });
});

// Get all users
app.get("/locations", (req, res) => {
  res.status(200).json(sharedData);
});

app.listen(PORT, () => {
  console.log(`🚀 Server running at http://localhost:${PORT}`);
});
