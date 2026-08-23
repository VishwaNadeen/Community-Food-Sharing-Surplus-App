import { PrismaClient } from "@prisma/client";
import { Server } from "http";

type ShutdownSignal = "SIGINT" | "SIGTERM";

export const registerShutdownHandlers = (
  server: Server,
  prisma: PrismaClient
): void => {
  let shuttingDown = false;

  const shutdown = async (signal: ShutdownSignal): Promise<void> => {
    if (shuttingDown) {
      return;
    }

    shuttingDown = true;
    console.log(`\n${signal} received, shutting down...`);

    server.close(async () => {
      await prisma.$disconnect();
      process.exit(0);
    });
  };

  process.on("SIGINT", () => {
    void shutdown("SIGINT");
  });

  process.on("SIGTERM", () => {
    void shutdown("SIGTERM");
  });
};
