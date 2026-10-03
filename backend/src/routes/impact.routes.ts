import { Router } from 'express';
import { getImpactAnalyticsHandler } from '../controllers/impact.controller';
import { authenticateToken, requireNgoCoordinator } from '../middleware/auth.middleware';

const router = Router();

router.use(authenticateToken, requireNgoCoordinator);
router.get('/', getImpactAnalyticsHandler);

export default router;
