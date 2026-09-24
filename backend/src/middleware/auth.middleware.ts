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

export const requireRole = (...allowedRoles: string[]) => {
    return (
        req: Request,
        res: Response<any, AuthLocals>,
        next: NextFunction
    ): void => {
        const currentUser = res.locals.currentUser;
        if (!currentUser || !currentUser.user) {
            res.status(401).json({ error: 'Authentication required' });
            return;
        }

        const userRole = currentUser.user.roleCode;
        if (!allowedRoles.includes(userRole)) {
            res.status(403).json({ error: 'Access denied. You do not have permission to perform this action.' });
            return;
        }

        next();
    };
};

export const requireNgoCoordinator = (
    req: Request,
    res: Response<any, AuthLocals>,
    next: NextFunction
): void => {
    const currentUser = res.locals.currentUser;
    if (!currentUser || !currentUser.user) {
        res.status(401).json({ error: 'Authentication required' });
        return;
    }

    if (currentUser.user.roleCode !== 'N') {
        res.status(403).json({ error: 'Access denied. Only NGO Coordinators can perform this action.' });
        return;
    }

    next();
};

export const requireVolunteer = (
    req: Request,
    res: Response<any, AuthLocals>,
    next: NextFunction
): void => {

    const currentUser =
        res.locals.currentUser;

    if (
        !currentUser ||
        !currentUser.user
    ) {

        res.status(401).json({
            error: 'Authentication required.'
        });

        return;
    }

    if (
        currentUser.user.roleCode !== 'V'
    ) {

        res.status(403).json({
            error:
                'Access denied. Only Volunteers can perform this action.'
        });

        return;
    }

    next();
};