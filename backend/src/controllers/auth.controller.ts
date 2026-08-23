import { Request, Response } from 'express';
import { loginUser, registerUser } from '../services/auth.service';
import { AuthLocals } from '../middleware/auth.middleware';
import { validateRegistrationInput } from '../validators/auth.validator';

// Registration endpoint
export const register = async (req: Request, res: Response): Promise<void> => {
    try {
        // Validate input data (only email, password, role)
        const validationErrors = validateRegistrationInput(req.body);
        if (validationErrors.length > 0) {
            res.status(400).json({ errors: validationErrors });
            return;
        }

        // Pass data to the service layer
        const user = await registerUser(req.body);

        // Response (only safe fields)
        res.status(201).json({ 
            message: 'User registered successfully', 
            user: {
                customUserId: user.customUserId,
                email: user.email,
                roleCode: user.roleCode
            } 
        });
    } catch (error: any) {
        res.status(500).json({ error: error.message });
    }
};

// Login and Me endpoints
export const login = async (req: Request, res: Response): Promise<void> => {
    try {
        const { email, password } = req.body;

        if (!email || !password) {
            res.status(400).json({ error: 'Email and password are required' });
            return;
        }

        const { user, token } = await loginUser(email, password);

        // Respond with safe fields only
        res.status(200).json({
            message: 'Login successful',
            token,
            user: {
                customUserId: user.customUserId,
                email: user.email,
                roleCode: user.roleCode
            }
        });
    } catch (error: any) {
        res.status(401).json({ error: error.message });
    }
};

// Get current user data from verified token
export const me = async (req: Request, res: Response<any, AuthLocals>): Promise<void> => {
    const currentUser = res.locals.currentUser;

    res.status(200).json({
        message: 'User data fetched successfully',
        user: currentUser.user
    });
};