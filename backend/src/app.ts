import express from "express";

import authRoutes from "./routes/auth.routes";
import donationRoutes from "./routes/donation.routes";
import ngoRoutes from "./routes/ngo.routes";
import matchingRoutes from "./routes/matching.routes";
import recipientRoutes from './routes/recipient.routes';
import foodRequestRoutes from './routes/foodRequest.routes';
import impactRoutes from './routes/impact.routes';
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
app.use('/requests', foodRequestRoutes);
app.use("/donations", donationRoutes);
app.use("/ngo/matches", matchingRoutes);
app.use('/ngo/impact', impactRoutes);
app.use('/volunteer', volunteerDeliveryRoutes);
app.use("/ngo", ngoRoutes);

export default app;
