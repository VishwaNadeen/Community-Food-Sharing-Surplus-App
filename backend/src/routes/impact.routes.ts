import { Router } from 'express';
import {
    getImpactAnalyticsHandler,
    getVolunteerActivityHandler
} from '../controllers/impact.controller';
import { authenticateToken, requireNgoCoordinator } from '../middleware/auth.middleware';

const router = Router();

router.use(authenticateToken, requireNgoCoordinator);
router.get('/volunteers', getVolunteerActivityHandler);
router.get('/', getImpactAnalyticsHandler);

export default router;
