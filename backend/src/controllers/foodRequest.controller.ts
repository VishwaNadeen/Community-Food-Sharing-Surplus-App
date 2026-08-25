import { Request, Response } from 'express';
import { AuthLocals } from '../middleware/auth.middleware';
import {
    approveFoodRequest,
    createFoodRequest,
    getAllFoodRequests,
    getFoodRequestById,
    getPendingFoodRequests,
    rejectFoodRequest
} from '../services/foodRequest.service';
import {
    validateCreateFoodRequestInput,
    validateRejectFoodRequestInput
} from '../validators/foodRequest.validator';

// GET /requests/pending - View pending food requests (NGO Coordinator)
export const getPendingFoodRequestsHandler = async (
    req: Request,
    res: Response<any, AuthLocals>
): Promise<void> => {
    try {
        const requests = await getPendingFoodRequests();
        res.status(200).json({
            message: 'Pending food requests fetched successfully',
            count: requests.length,
            requests
        });
    } catch (error: any) {
        res.status(500).json({ error: error.message });
    }
};

// GET /requests/:id - View food request details (Recipient info and requested food)
export const getFoodRequestByIdHandler = async (
    req: Request,
    res: Response<any, AuthLocals>
): Promise<void> => {
    try {
        const id = Array.isArray(req.params.id) ? req.params.id[0] : String(req.params.id);
        const foodRequest = await getFoodRequestById(id);
        res.status(200).json({
            message: 'Food request details fetched successfully',
            request: foodRequest
        });
    } catch (error: any) {
        if (error.message === 'Food request not found') {
            res.status(404).json({ error: error.message });
            return;
        }
        res.status(500).json({ error: error.message });
    }
};

// PATCH/POST /requests/:id/approve - Approve food request (NGO Coordinator)
export const approveFoodRequestHandler = async (
    req: Request,
    res: Response<any, AuthLocals>
): Promise<void> => {
    try {
        const id = Array.isArray(req.params.id) ? req.params.id[0] : String(req.params.id);
        const coordinatorCustomUserId = res.locals.currentUser.user.customUserId;

        const updatedRequest = await approveFoodRequest(id, coordinatorCustomUserId);
        res.status(200).json({
            message: 'Food request approved successfully',
            request: updatedRequest
        });
    } catch (error: any) {
        if (error.message === 'Food request not found') {
            res.status(404).json({ error: error.message });
            return;
        }
        if (error.message.includes('Cannot approve request with status')) {
            res.status(400).json({ error: error.message });
            return;
        }
        res.status(500).json({ error: error.message });
    }
};

// PATCH/POST /requests/:id/reject - Reject food request with reason (NGO Coordinator)
export const rejectFoodRequestHandler = async (
    req: Request,
    res: Response<any, AuthLocals>
): Promise<void> => {
    try {
        const id = Array.isArray(req.params.id) ? req.params.id[0] : String(req.params.id);
        const validationErrors = validateRejectFoodRequestInput(req.body);
        if (validationErrors.length > 0) {
            res.status(400).json({ errors: validationErrors });
            return;
        }

        const { rejectionReason } = req.body;
        const coordinatorCustomUserId = res.locals.currentUser.user.customUserId;

        const updatedRequest = await rejectFoodRequest(id, rejectionReason, coordinatorCustomUserId);
        res.status(200).json({
            message: 'Food request rejected successfully',
            request: updatedRequest
        });
    } catch (error: any) {
        if (error.message === 'Food request not found') {
            res.status(404).json({ error: error.message });
            return;
        }
        if (error.message.includes('Cannot reject request with status') || error.message === 'Rejection reason is required') {
            res.status(400).json({ error: error.message });
            return;
        }
        res.status(500).json({ error: error.message });
    }
};

// POST /requests - Submit a new recipient food request
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

        const currentUser = res.locals.currentUser.user;
        const foodRequest = await createFoodRequest(req.body, {
            customUserId: currentUser.customUserId,
            email: currentUser.email
        });

        res.status(201).json({
            message: 'Food request submitted successfully',
            request: foodRequest
        });
    } catch (error: any) {
        res.status(500).json({ error: error.message });
    }
};

// GET /requests - View all food requests with optional query filters
export const getAllFoodRequestsHandler = async (
    req: Request,
    res: Response<any, AuthLocals>
): Promise<void> => {
    try {
        const status = req.query.status as string | undefined;
        const recipientId = req.query.recipientId as string | undefined;

        const requests = await getAllFoodRequests({ status, recipientId });
        res.status(200).json({
            message: 'Food requests fetched successfully',
            count: requests.length,
            requests
        });
    } catch (error: any) {
        res.status(500).json({ error: error.message });
    }
};
