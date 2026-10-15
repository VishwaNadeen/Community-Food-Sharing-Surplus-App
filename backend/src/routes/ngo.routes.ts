import { Router } from 'express';
import {
    approveDonationHandler,
    approveFoodRequestHandler,
    getAllDonationsHandler,
    getAllFoodRequestsHandler,
    getDonationByIdHandler,
    getFoodRequestByIdHandler,
    getPendingDonationsHandler,
    getPendingFoodRequestsHandler,
    rejectDonationHandler,
    rejectFoodRequestHandler,
    generateMatchesHandler,
    getMatchesHandler
} from '../controllers/ngo.controller';
import { authenticateToken, requireNgoCoordinator } from '../middleware/auth.middleware';
import { getNgoProfileHandler, updateNgoProfileHandler, uploadNgoProfilePhotoHandler } from '../controllers/ngoProfile.controller';
import upload, { handleUploadError } from '../middleware/upload.middleware';

const router = Router();

// Protect all /ngo routes exclusively for authenticated NGO Coordinators
router.use(authenticateToken, requireNgoCoordinator);

router.get('/profile', getNgoProfileHandler);
router.put('/profile', updateNgoProfileHandler);
router.post('/profile/photo', upload.single('image'), handleUploadError, uploadNgoProfilePhotoHandler);

// FOOD DONATION REVIEW ROUTES
router.get('/donations/pending', getPendingDonationsHandler);
router.get('/donations/:id', getDonationByIdHandler);
router.patch('/donations/:id/approve', approveDonationHandler);
router.post('/donations/:id/approve', approveDonationHandler);
router.patch('/donations/:id/reject', rejectDonationHandler);
router.post('/donations/:id/reject', rejectDonationHandler);
router.get('/donations', getAllDonationsHandler);

// RECIPIENT FOOD REQUEST REVIEW ROUTES
router.get('/requests/pending', getPendingFoodRequestsHandler);
router.get('/requests/:id', getFoodRequestByIdHandler);
router.patch('/requests/:id/approve', approveFoodRequestHandler);
router.post('/requests/:id/approve', approveFoodRequestHandler);
router.patch('/requests/:id/reject', rejectFoodRequestHandler);
router.post('/requests/:id/reject', rejectFoodRequestHandler);
router.get('/requests', getAllFoodRequestsHandler);

// FOOD MATCHING ROUTES (CFSASA-60)
router.post('/matches/generate', generateMatchesHandler);
router.get('/matches', getMatchesHandler);

export default router;
