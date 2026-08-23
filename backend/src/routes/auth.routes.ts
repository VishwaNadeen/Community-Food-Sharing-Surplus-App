import { Router } from 'express';
import { register, login, me } from '../controllers/auth.controller';
import { authenticateToken } from '../middleware/auth.middleware';

const router = Router();

// Registration route
router.post('/register', register);
router.post('/login', login);
router.get('/me', authenticateToken, me);

export default router;