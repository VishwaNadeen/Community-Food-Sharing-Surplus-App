import { Request, Response } from 'express';

import { AuthLocals } from '../middleware/auth.middleware';

import {
    createRecipientProfile,
    getRecipientProfile,
    updateRecipientProfile,
    deleteRecipientProfile,
    getRecipientProfileStatus
} from '../services/recipient.service';

import {
    validateRecipientProfileInput,
    validateRecipientProfileUpdate
} from '../validators/recipient.validator';

import {
    createFoodRequest,
    confirmFoodReceived,
    getAllFoodRequests
} from '../services/foodRequest.service';

import {
    validateCreateFoodRequestInput
} from '../validators/foodRequest.validator';


// ====================== CREATE PROFILE ======================

export const createProfile = async (
    req: Request,
    res: Response<any, AuthLocals>
): Promise<void> => {

    try {

        const currentUser = res.locals.currentUser;

        if (currentUser.user.roleCode !== 'R') {
            res.status(403).json({
                error: 'Only recipients can create a recipient profile'
            });

            return;
        }

        const validationErrors =
            validateRecipientProfileInput(req.body);

        if (validationErrors.length > 0) {

            res.status(400).json({
                errors: validationErrors
            });

            return;
        }

        const profile = await createRecipientProfile(
            currentUser.user.customUserId,
            req.body
        );

        res.status(201).json({

            message: 'Recipient profile completed successfully',

            profile
        });

    } catch (error: any) {

        res.status(400).json({
            error: error.message
        });

    }
};


// ====================== GET PROFILE ======================

export const getProfile = async (
    req: Request,
    res: Response<any, AuthLocals>
): Promise<void> => {

    try {

        const currentUser = res.locals.currentUser;

        const profile = await getRecipientProfile(
            currentUser.user.customUserId
        );

        res.status(200).json({

            message: 'Recipient profile fetched successfully',

            profile
        });

    } catch (error: any) {

        res.status(404).json({
            error: error.message
        });

    }
};


// ====================== UPDATE PROFILE ======================

export const updateProfile = async (
    req: Request,
    res: Response<any, AuthLocals>
): Promise<void> => {

    try {

        const validationErrors =
            validateRecipientProfileUpdate(req.body);

        if (validationErrors.length > 0) {

            res.status(400).json({
                errors: validationErrors
            });

            return;
        }

        const currentUser = res.locals.currentUser;

        const profile = await updateRecipientProfile(
            currentUser.user.customUserId,
            req.body
        );

        res.status(200).json({

            message: 'Recipient profile updated successfully',

            profile
        });

    } catch (error: any) {

        res.status(400).json({
            error: error.message
        });

    }
};


// ====================== DELETE PROFILE ======================

export const deleteProfile = async (
    req: Request,
    res: Response<any, AuthLocals>
): Promise<void> => {

    try {

        const currentUser = res.locals.currentUser;

        await deleteRecipientProfile(
            currentUser.user.customUserId
        );

        res.status(200).json({

            message: 'Recipient profile deleted successfully',

            profileCompleted: false
        });

    } catch (error: any) {

        res.status(400).json({
            error: error.message
        });

    }
};


// ====================== PROFILE STATUS ======================

export const checkProfileStatus = async (
    req: Request,
    res: Response<any, AuthLocals>
): Promise<void> => {

    try {

        const currentUser = res.locals.currentUser;

        const status = await getRecipientProfileStatus(
            currentUser.user.customUserId
        );

        res.status(200).json({

            message: 'Profile status fetched successfully',

            ...status
        });

    } catch (error: any) {

        res.status(400).json({
            error: error.message
        });

    }
};


// ====================== MY FOOD REQUESTS ======================

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

        const currentUser = res.locals.currentUser;
        const request = await createFoodRequest(req.body, {
            customUserId: currentUser.user.customUserId,
            email: currentUser.user.email
        });

        res.status(201).json({
            message: 'Food claim submitted successfully',
            request
        });
    } catch (error: any) {
        res.status(500).json({ error: error.message });
    }
};

export const getMyRequestsHandler = async (
    req: Request,
    res: Response<any, AuthLocals>
): Promise<void> => {

    try {

        const currentUser = res.locals.currentUser;

        const requests = await getAllFoodRequests({
            recipientId: currentUser.user.customUserId
        });

        res.status(200).json({

            message: 'Your food requests fetched successfully',

            count: requests.length,

            requests
        });

    } catch (error: any) {

        res.status(500).json({
            error: error.message
        });

    }
};


// ====================== CONFIRM FOOD RECEIVED ======================

export const confirmReceivedHandler = async (
    req: Request,
    res: Response<any, AuthLocals>
): Promise<void> => {

    try {

        const currentUser = res.locals.currentUser;
        const id = Array.isArray(req.params.id) ? req.params.id[0] : String(req.params.id);

        const updatedRequest = await confirmFoodReceived(
            id,
            currentUser.user.customUserId
        );

        res.status(200).json({

            message: 'Food delivery confirmed as received successfully',

            request: updatedRequest
        });

    } catch (error: any) {

        if (error.message === 'Food request not found') {
            res.status(404).json({ error: error.message });
            return;
        }

        if (error.message.includes('Cannot confirm receipt') || error.message.includes('only confirm receipt')) {
            res.status(400).json({ error: error.message });
            return;
        }

        res.status(500).json({
            error: error.message
        });

    }
};
