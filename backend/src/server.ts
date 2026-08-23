import "dotenv/config";
import express from "express";
import { PrismaClient } from "@prisma/client";

import authRoutes from "./routes/auth.routes"; 

const app = express();
const PORT = 5000;

const prisma = new PrismaClient();

app.use(express.json());

app.get("/", (req, res) => {
  res.json({
    message: "Server is running successfully!",
  });
});

app.use("/auth", authRoutes);

async function startServer() {
  try {
    await prisma.$connect();

    console.log("✅ Connected to MongoDB");

    app.listen(PORT, () => {
      console.log(`🚀 Server running on http://localhost:${PORT}`);
    });
  } catch (error) {
    console.error("❌ Failed to connect to MongoDB:", error);
    await prisma.$disconnect();
    process.exit(1);
  }
}

startServer();