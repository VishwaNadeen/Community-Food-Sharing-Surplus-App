import { Router } from 'express';

import {
    createProfile,
    getProfile,
    updateProfile,
    deleteProfile,
    checkProfileStatus,
    createFoodRequestHandler,
    getMyRequestsHandler,
    confirmReceivedHandler
} from '../controllers/recipient.controller';

import {
    browseDonations,
    getDonationDetails
} from '../controllers/recipientDonation.controller';

import {
    authenticateToken,
    requireRole
} from '../middleware/auth.middleware';

const router = Router();

// All recipient routes require authentication.
router.use(authenticateToken);

// Only users with role R can access these routes.
router.use(requireRole('R'));

// ====================== FOOD DONATION BROWSING ======================

// Browse available food donations with optional filters.
//
// Examples:
// GET /api/recipients/donations
// GET /api/recipients/donations?category=rice
// GET /api/recipients/donations?location=Malabe
// GET /api/recipients/donations?category=rice&location=Malabe
// GET /api/recipients/donations?availability=available
// GET /api/recipients/donations?availability=unavailable
// GET /api/recipients/donations?availability=all

router.get(
    '/donations',
    browseDonations
);

// View details of one currently available food donation.

router.get(
    '/donations/:id',
    getDonationDetails
);

// ====================== FOOD REQUESTS ======================

// Get recipient's own food requests.

router.post(
    '/requests',
    createFoodRequestHandler
);

router.get(
    '/requests',
    getMyRequestsHandler
);

// Confirm food delivery received (APPROVED → COMPLETED).

router.patch(
    '/requests/:id/confirm-received',
    confirmReceivedHandler
);

// ====================== PROFILE ======================

// Check profile completion status.

router.get(
    '/status',
    checkProfileStatus
);

router.get(
    '/profile/status',
    checkProfileStatus
);

// Create recipient profile after login.

router.post(
    '/profile',
    createProfile
);

// Get recipient profile.

router.get(
    '/profile',
    getProfile
);

// Update recipient profile.

router.put(
    '/profile',
    updateProfile
);

// Delete recipient profile.

router.delete(
    '/profile',
    deleteProfile
);

export default router;
