import { Router } from 'express';
import { create } from '../controllers/donation.controller';
import { authenticateToken } from '../middleware/auth.middleware';
import upload from '../middleware/upload.middleware';

const router = Router();

router.post('/', authenticateToken, upload.single('image'), create);

export default router;