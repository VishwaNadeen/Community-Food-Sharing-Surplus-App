import express from "express";

import authRoutes from "./routes/auth.routes";
import donationRoutes from "./routes/donation.routes";
import foodRequestRoutes from "./routes/foodRequest.routes";
import volunteerDeliveryRoutes from './routes/volunteerDelivery.routes';

const app = express();

app.use(express.json());

app.get("/", (req, res) => {
  res.json({
    message: "Server is running successfully!",
  });
});

app.use("/auth", authRoutes);
app.use("/donations", donationRoutes);
app.use("/requests", foodRequestRoutes);
app.use("/volunteer", volunteerDeliveryRoutes);

export default app;