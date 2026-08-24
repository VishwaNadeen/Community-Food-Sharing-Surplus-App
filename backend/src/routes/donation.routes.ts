import { Router } from 'express';
import { create, getMyDonations } from '../controllers/donation.controller';
import { authenticateToken } from '../middleware/auth.middleware';
import upload from '../middleware/upload.middleware';

const router = Router();

router.post('/', authenticateToken, upload.single('image'), create);
router.get('/', authenticateToken, getMyDonations);

export default router;