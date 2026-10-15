
import { Router } from 'express';

import {
    authenticateToken,
    requireRole
} from '../middleware/auth.middleware';

import {
    getDonorProfileHandler,
    createDonorProfileHandler,
    updateDonorProfileHandler,
    getDonorProfileStatusHandler,
    getDonorDeliveriesHandler
} from '../controllers/donor.controller';

const router = Router();

// All donor endpoints require authentication and the donor role.
router.use(authenticateToken, requireRole('D'));

// GET /api/donors/profile
router.get('/profile', getDonorProfileHandler);

// GET /api/donors/profile/status
router.get('/profile/status', getDonorProfileStatusHandler);

// POST /api/donors/profile
router.post('/profile', createDonorProfileHandler);

// GET /api/donors/deliveries
// Deliveries of this donor's food that a volunteer has accepted.
router.get('/deliveries', getDonorDeliveriesHandler);

// PUT /api/donors/profile
router.put('/profile', updateDonorProfileHandler);

export default router;
