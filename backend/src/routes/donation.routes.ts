import { Router } from 'express';
import { create } from '../controllers/donation.controller';
import { authenticateToken } from '../middleware/auth.middleware';

const router = Router();

router.post('/', authenticateToken, create);

export default router;