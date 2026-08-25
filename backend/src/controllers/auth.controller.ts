import { Request, Response } from 'express';
import {
    loginUser,
    registerUser,
    resendVerificationEmail,
    verifyEmail,
    requestPasswordReset,
    resetPassword,
    changePassword
} from '../services/auth.service';
import { AuthLocals } from '../middleware/auth.middleware';
import { validateRegistrationInput } from '../validators/auth.validator';

// Registration
export const register = async (req: Request, res: Response): Promise<void> => {
    try {
        const validationErrors = validateRegistrationInput(req.body);
        if (validationErrors.length > 0) {
            res.status(400).json({ errors: validationErrors });
            return;
        }

        const user = await registerUser(req.body);

        res.status(201).json({
            message: 'Verification code sent to email',
            user: {
                customUserId: user.customUserId,
                email: user.email,
                roleCode: user.roleCode,
                isEmailVerified: user.isEmailVerified,
                createdAt: user.createdAt,
                updatedAt: user.updatedAt
            }
        });
    } catch (error: any) {
        res.status(500).json({ error: error.message });
    }
};

// Login
export const login = async (req: Request, res: Response): Promise<void> => {
    try {
        const { email, password } = req.body;

        if (!email || !password) {
            res.status(400).json({ error: 'Email and password are required' });
            return;
        }

        const { user, token, profileCompleted } = await loginUser(email, password);

        res.status(200).json({
            message: 'Login successful',
            token,
            profileCompleted,
            user: {
                customUserId: user.customUserId,
                email: user.email,
                roleCode: user.roleCode
            }
        });
    } catch (error: any) {
        const statusCode = error.message === 'Please verify your email first' ? 403 : 401;
        res.status(statusCode).json({ error: error.message });
    }
};

// Get current user
export const me = async (req: Request, res: Response<any, AuthLocals>): Promise<void> => {
    const currentUser = res.locals.currentUser;

    res.status(200).json({
        message: 'User data fetched successfully',
        user: currentUser.user
    });
};

// Verify email OTP
export const verify = async (req: Request, res: Response): Promise<void> => {
    try {
        const { email, code } = req.body;

        if (!email || !code) {
            res.status(400).json({ error: 'Email and verification code are required' });
            return;
        }

        const user = await verifyEmail(email, code);

        res.status(200).json({
            message: 'Email verified successfully',
            user: {
                customUserId: user.customUserId,
                email: user.email,
                roleCode: user.roleCode,
                isEmailVerified: user.isEmailVerified,
                createdAt: user.createdAt,
                updatedAt: user.updatedAt
            }
        });
    } catch (error: any) {
        res.status(400).json({ error: error.message });
    }
};

// Resend verification OTP
export const resendVerification = async (req: Request, res: Response): Promise<void> => {
    try {
        const { email } = req.body;

        if (!email) {
            res.status(400).json({ error: 'Email is required' });
            return;
        }

        const user = await resendVerificationEmail(email);

        res.status(200).json({
            message: 'Verification code resent to email',
            user: {
                customUserId: user.customUserId,
                email: user.email,
                roleCode: user.roleCode,
                isEmailVerified: user.isEmailVerified,
                createdAt: user.createdAt,
                updatedAt: user.updatedAt
            }
        });
    } catch (error: any) {
        res.status(400).json({ error: error.message });
    }
};

// ====================== PASSWORD RESET ======================
export const forgotPassword = async (req: Request, res: Response): Promise<void> => {
    try {
        const { email } = req.body;

        if (!email) {
            res.status(400).json({ error: 'Email is required' });
            return;
        }

        await requestPasswordReset(email);

        // Always return success to avoid email enumeration
        res.status(200).json({
            message: 'If an account with that email exists, a password reset code has been sent'
        });
    } catch (error: any) {
        res.status(400).json({ error: error.message });
    }
};

export const resetPasswordHandler = async (req: Request, res: Response): Promise<void> => {
    try {
        const { email, code, newPassword } = req.body;

        if (!email || !code || !newPassword) {
            res.status(400).json({ error: 'Email, code and new password are required' });
            return;
        }

        if (newPassword.length < 6) {
            res.status(400).json({ error: 'Password must be at least 6 characters' });
            return;
        }

        await resetPassword(email, code, newPassword);

        res.status(200).json({
            message: 'Password has been reset successfully'
        });
    } catch (error: any) {
        res.status(400).json({ error: error.message });
    }
};

// ====================== CHANGE PASSWORD (authenticated) ======================
export const changePasswordHandler = async (
    req: Request,
    res: Response<any, AuthLocals>
): Promise<void> => {
    try {
        const { oldPassword, newPassword } = req.body;
        const currentUser = res.locals.currentUser;

        if (!oldPassword || !newPassword) {
            res.status(400).json({ error: 'Old password and new password are required' });
            return;
        }

        if (newPassword.length < 6) {
            res.status(400).json({ error: 'New password must be at least 6 characters' });
            return;
        }

        await changePassword(currentUser.user.id, oldPassword, newPassword);

        res.status(200).json({
            message: 'Password changed successfully'
        });
    } catch (error: any) {
        res.status(400).json({ error: error.message });
    }
};