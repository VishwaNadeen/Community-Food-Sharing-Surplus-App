import { Router } from 'express';
import {
    approveDonationHandler,
    createDonationHandler,
    getAllDonationsHandler,
    getDonationByIdHandler,
    getPendingDonationsHandler,
    rejectDonationHandler
} from '../controllers/donation.controller';
import { authenticateToken, requireNgoCoordinator } from '../middleware/auth.middleware';

const router = Router();

// NGO Coordinator specific routes
router.get('/pending', authenticateToken, requireNgoCoordinator, getPendingDonationsHandler);
router.patch('/:id/approve', authenticateToken, requireNgoCoordinator, approveDonationHandler);
router.post('/:id/approve', authenticateToken, requireNgoCoordinator, approveDonationHandler);
router.patch('/:id/reject', authenticateToken, requireNgoCoordinator, rejectDonationHandler);
router.post('/:id/reject', authenticateToken, requireNgoCoordinator, rejectDonationHandler);

// General donation routes (Details & Creation)
router.get('/:id', authenticateToken, getDonationByIdHandler);
router.post('/', authenticateToken, createDonationHandler);
router.get('/', authenticateToken, getAllDonationsHandler);

export default router;
