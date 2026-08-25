import { Router } from 'express';
import {
    register,
    login,
    me,
    verify,
    resendVerification,
    forgotPassword,
    resetPasswordHandler,
    changePasswordHandler
} from '../controllers/auth.controller';
import { authenticateToken } from '../middleware/auth.middleware';

const router = Router();

// Public routes
router.post('/register', register);
router.post('/login', login);
router.post('/verify-email', verify);
router.post('/resend-verification', resendVerification);

// Password reset
router.post('/forgot-password', forgotPassword);
router.post('/reset-password', resetPasswordHandler);

// Protected routes
router.get('/me', authenticateToken, me);
router.post('/change-password', authenticateToken, changePasswordHandler);

export default router;