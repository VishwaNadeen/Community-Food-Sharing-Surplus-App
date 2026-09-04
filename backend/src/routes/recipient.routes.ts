import { Router } from 'express';

import {
    createProfile,
    getProfile,
    updateProfile,
    deleteProfile,
    checkProfileStatus
} from '../controllers/recipient.controller';

import {
    authenticateToken,
    requireRole
} from '../middleware/auth.middleware';


const router = Router();


// All recipient routes require authentication

router.use(authenticateToken);


// Only users with role R can access these routes

router.use(requireRole('R'));


// Check profile completion status

router.get(
    '/status',
    checkProfileStatus
);


// Create recipient profile

router.post(
    '/profile',
    createProfile
);


// Get recipient profile

router.get(
    '/profile',
    getProfile
);


// Update recipient profile

router.put(
    '/profile',
    updateProfile
);


// Delete recipient profile

router.delete(
    '/profile',
    deleteProfile
);


export default router;