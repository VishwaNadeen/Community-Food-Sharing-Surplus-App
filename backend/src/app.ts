import express from "express";

import authRoutes from "./routes/auth.routes";
import donationRoutes from "./routes/donation.routes";
import ngoRoutes from "./routes/ngo.routes";
import recipientRoutes from './routes/recipient.routes';
import volunteerDeliveryRoutes from './routes/volunteerDelivery.routes';

const app = express();

app.use(express.json());

app.get("/", (req, res) => {
  res.json({
    message: "Server is running successfully!",
  });
});

app.use("/auth", authRoutes);
app.use('/api/recipients', recipientRoutes);
app.use("/donations", donationRoutes);
app.use("/requests", foodRequestRoutes);
app.use('/volunteer', volunteerDeliveryRoutes);
app.use("/ngo", ngoRoutes);

export default app;