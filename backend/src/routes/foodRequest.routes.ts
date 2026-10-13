
import { Router } from 'express';
import {
    approveFoodRequestHandler,
    createFoodRequestHandler,
    getAllFoodRequestsHandler,
    getFoodRequestByIdHandler,
    getMyFoodRequestsHandler,
    getPendingFoodRequestsHandler,
    rejectFoodRequestHandler
} from '../controllers/foodRequest.controller';
import {
    authenticateToken,
    requireNgoCoordinator,
    requireRole
} from '../middleware/auth.middleware';

const router = Router();

// NGO Coordinator routes
router.get(
    '/pending',
    authenticateToken,
    requireNgoCoordinator,
    getPendingFoodRequestsHandler
);

router.patch(
    '/:id/approve',
    authenticateToken,
    requireNgoCoordinator,
    approveFoodRequestHandler
);

router.post(
    '/:id/approve',
    authenticateToken,
    requireNgoCoordinator,
    approveFoodRequestHandler
);

router.patch(
    '/:id/reject',
    authenticateToken,
    requireNgoCoordinator,
    rejectFoodRequestHandler
);

router.post(
    '/:id/reject',
    authenticateToken,
    requireNgoCoordinator,
    rejectFoodRequestHandler
);

// Recipient routes
router.post(
    '/',
    authenticateToken,
    requireRole('R'),
    createFoodRequestHandler
);

router.get(
    '/mine',
    authenticateToken,
    requireRole('R'),
    getMyFoodRequestsHandler
);

// General authenticated routes
router.get(
    '/',
    authenticateToken,
    getAllFoodRequestsHandler
);

router.get(
    '/:id',
    authenticateToken,
    getFoodRequestByIdHandler
);

export default router;
