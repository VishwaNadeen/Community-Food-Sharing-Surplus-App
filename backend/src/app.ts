import express from "express";

import authRoutes from "./routes/auth.routes";
import donationRoutes from "./routes/donation.routes";

const app = express();

app.use(express.json());

app.get("/", (req, res) => {
  res.json({
    message: "Server is running successfully!",
  });
});

app.use("/auth", authRoutes);
app.use("/donations", donationRoutes);

export default app;