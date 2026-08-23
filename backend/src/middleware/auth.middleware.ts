import { NextFunction, Request, Response } from 'express';
import { CurrentUserResult, getCurrentUserFromToken } from '../services/auth.service';

export interface AuthLocals {
    currentUser: CurrentUserResult;
}

export const authenticateToken = async (
    req: Request,
    res: Response<any, AuthLocals>,
    next: NextFunction
): Promise<void> => {
    try {
        const authorizationHeader = req.headers.authorization;
        if (!authorizationHeader || !authorizationHeader.startsWith('Bearer ')) {
            res.status(401).json({ error: 'Authorization token is required' });
            return;
        }

        const token = authorizationHeader.slice(7).trim();
        const currentUser = await getCurrentUserFromToken(token);

        res.locals.currentUser = currentUser;
        next();
    } catch (error: any) {
        res.status(401).json({ error: error.message });
    }
};
