import "dotenv/config";
import { PrismaClient } from "@prisma/client";
import app from "./app";
import { registerShutdownHandlers } from "./utils/shutdown";
const PORT = 5001;

const prisma = new PrismaClient();
let server: ReturnType<typeof app.listen> | undefined;

// Graceful shutdown
async function startServer() {
  try {
    await prisma.$connect();

    console.log("✅ Connected to MongoDB");

    server = app.listen(PORT, () => {
      console.log(`🚀 Server running on http://localhost:${PORT}`);
    });
    registerShutdownHandlers(server, prisma);
  } catch (error) {
    console.error("❌ Failed to connect to MongoDB:", error);
    await prisma.$disconnect();
    process.exit(1);
  }
}

startServer();