import { Router } from 'express';
import {
    getImpactAnalyticsHandler,
    getImpactReportHandler,
    getVolunteerActivityHandler
} from '../controllers/ngoImpact.controller';
import { authenticateToken, requireNgoCoordinator } from '../middleware/auth.middleware';

const router = Router();

router.use(authenticateToken, requireNgoCoordinator);
router.get('/volunteers', getVolunteerActivityHandler);
router.get('/report', getImpactReportHandler);
router.get('/', getImpactAnalyticsHandler);

export default router;
