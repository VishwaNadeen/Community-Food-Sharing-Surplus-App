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