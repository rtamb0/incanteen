const express = require("express");
const cors = require("cors");
const { PORT } = require("./src/config/env");
const authRoutes = require("./src/routes/authRoutes");

const app = express();

// Middlewares
app.use(cors());
app.use(express.json());

// Routes
app.use("/api/auth", authRoutes);

// Default route
app.get("/", (req, res) => res.send("Server is running"));

// Start server
app.listen(PORT, () => console.log(`Server running on port ${PORT}`));
