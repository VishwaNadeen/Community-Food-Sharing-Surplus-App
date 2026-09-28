import { Request, Response } from 'express';

import { AuthLocals } from '../middleware/auth.middleware';
import {
    createFoodRequest,
    getAllFoodRequests
} from '../services/foodRequest.service';
import { validateCreateFoodRequestInput } from '../validators/foodRequest.validator';

// POST /requests - Submit a food request as the authenticated recipient.
export const createFoodRequestHandler = async (
    req: Request,
    res: Response<any, AuthLocals>
): Promise<void> => {
    try {
        const validationErrors = validateCreateFoodRequestInput(req.body);
        if (validationErrors.length > 0) {
            res.status(400).json({ errors: validationErrors });
            return;
        }

        const user = res.locals.currentUser.user;
        const request = await createFoodRequest(req.body, {
            customUserId: user.customUserId,
            email: user.email
        });

        res.status(201).json({
            message: 'Food request submitted successfully',
            request
        });
    } catch (error: any) {
        res.status(500).json({ error: error.message });
    }
};

// GET /requests - View only the authenticated recipient's requests.
export const getMyFoodRequestsHandler = async (
    req: Request,
    res: Response<any, AuthLocals>
): Promise<void> => {
    try {
        const recipientId = res.locals.currentUser.user.customUserId;
        const requests = await getAllFoodRequests({ recipientId });

        res.status(200).json({
            message: 'Food requests fetched successfully',
            count: requests.length,
            requests
        });
    } catch (error: any) {
        res.status(500).json({ error: error.message });
    }
};
