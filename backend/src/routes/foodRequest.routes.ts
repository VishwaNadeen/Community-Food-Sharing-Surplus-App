import { Router } from 'express';
import {
    approveFoodRequestHandler,
    createFoodRequestHandler,
    getAllFoodRequestsHandler,
    getFoodRequestByIdHandler,
    getPendingFoodRequestsHandler,
    rejectFoodRequestHandler
} from '../controllers/foodRequest.controller';
import { authenticateToken, requireNgoCoordinator } from '../middleware/auth.middleware';

const router = Router();

// NGO Coordinator specific routes
router.get('/pending', authenticateToken, requireNgoCoordinator, getPendingFoodRequestsHandler);
router.patch('/:id/approve', authenticateToken, requireNgoCoordinator, approveFoodRequestHandler);
router.post('/:id/approve', authenticateToken, requireNgoCoordinator, approveFoodRequestHandler);
router.patch('/:id/reject', authenticateToken, requireNgoCoordinator, rejectFoodRequestHandler);
router.post('/:id/reject', authenticateToken, requireNgoCoordinator, rejectFoodRequestHandler);

// General food request routes (Details, Creation, List)
router.get('/:id', authenticateToken, getFoodRequestByIdHandler);
router.post('/', authenticateToken, createFoodRequestHandler);
router.get('/', authenticateToken, getAllFoodRequestsHandler);

export default router;
