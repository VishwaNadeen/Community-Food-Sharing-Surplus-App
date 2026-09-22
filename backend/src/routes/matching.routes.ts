import { Router } from 'express';
import {
    generateFoodMatchesHandler,
    getFoodMatchesHandler
} from '../controllers/matching.controller';
import { authenticateToken, requireNgoCoordinator } from '../middleware/auth.middleware';

const router = Router();

router.use(authenticateToken, requireNgoCoordinator);
router.post('/generate', generateFoodMatchesHandler);
router.get('/', getFoodMatchesHandler);

export default router;
