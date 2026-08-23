import { Request, Response } from 'express';
import * as authService from '../services/auth.service';
import { validateRegistrationInput } from '../validators/auth.validator';

export const register = async (req: Request, res: Response): Promise<void> => {
    try {
        // Validate input data (only email, password, role)
        const validationErrors = validateRegistrationInput(req.body);
        if (validationErrors.length > 0) {
            res.status(400).json({ errors: validationErrors });
            return;
        }

        // Pass data to the service layer
        const user = await authService.registerUser(req.body);

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

export const login = async (req: Request, res: Response): Promise<void> => {
    try {
        const { email, password } = req.body;

        if (!email || !password) {
            res.status(400).json({ error: 'Email and password are required' });
            return;
        }

        const user = await authService.loginUser(email, password);

        // Respond with safe fields only
        res.status(200).json({
            message: 'Login successful',
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