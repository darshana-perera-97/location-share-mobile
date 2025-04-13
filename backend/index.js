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

const locationsFile = path.join(__dirname, "locations.json");
let locationData = [];

// Load existing locations
if (fs.existsSync(locationsFile)) {
  const raw = fs.readFileSync(locationsFile);
  locationData = JSON.parse(raw || "[]");
}

function saveLocations() {
  fs.writeFileSync(locationsFile, JSON.stringify(locationData, null, 2));
}

// New endpoint: Accept userID + location
app.post("/send-location", (req, res) => {
  const { userId, lat, lng } = req.body;

  if (!userId || lat == null || lng == null) {
    return res.status(400).json({ message: "Missing required fields" });
  }

  const newLoc = {
    userId,
    timestamp: new Date().toISOString(),
    location: { lat, lng },
  };

  locationData.push(newLoc);
  saveLocations();

  console.log("📍 Location received:", newLoc);
  res.status(200).json({ message: "Location saved", data: newLoc });
});

// GET: locations by userId
app.get('/locations/:userId', (req, res) => {
  const { userId } = req.params;
  const filtered = locationData.filter(loc => loc.userId === userId);
  res.status(200).json(filtered);
});


app.listen(PORT, () => {
  console.log(`🚀 Server running at http://localhost:${PORT}`);
});
