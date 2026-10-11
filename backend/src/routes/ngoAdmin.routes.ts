import { Router } from 'express';
import {
    getAdminOverviewHandler,
    getAlertsHandler,
    getDonorsHandler,
    getRecipientsHandler,
    updateAlertStatusHandler
} from '../controllers/ngoAdmin.controller';
import { authenticateToken, requireNgoCoordinator } from '../middleware/auth.middleware';

const router = Router();

router.use(authenticateToken, requireNgoCoordinator);

router.get('/overview', getAdminOverviewHandler);
router.get('/donors', getDonorsHandler);
router.get('/recipients', getRecipientsHandler);
router.get('/alerts', getAlertsHandler);
router.patch('/alerts/:id/status', updateAlertStatusHandler);

export default router;
