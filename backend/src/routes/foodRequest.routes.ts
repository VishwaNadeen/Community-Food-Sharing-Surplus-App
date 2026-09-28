import { Router } from 'express';

import {
    createFoodRequestHandler,
    getMyFoodRequestsHandler
} from '../controllers/foodRequest.controller';
import { authenticateToken, requireRole } from '../middleware/auth.middleware';

const router = Router();

// A request belongs to the logged-in recipient, never to an ID supplied by a client.
router.use(authenticateToken);
router.use(requireRole('R'));

router.post('/', createFoodRequestHandler);
router.get('/', getMyFoodRequestsHandler);

export default router;
