
import { Request, Response } from 'express';

import {
    createDonorProfile,
    getDonorProfile,
    updateDonorProfile,
    getDonorProfileStatus,
    DonorProfileInput
} from '../services/donor.service';

import { getDonorDeliveries } from '../services/donorDelivery.service';

import { AuthLocals } from '../middleware/auth.middleware';

type AuthRequest = Request & {
    body: DonorProfileInput;
};

// ====================== GET DONOR PROFILE ======================

export const getDonorProfileHandler = async (
    req: Request,
    res: Response,
): Promise<void> => {
    try {
        const customUserId = res.locals.currentUser.user.customUserId;

        const profile = await getDonorProfile(customUserId);

        res.status(200).json({
            profile,
            profileCompleted: !!profile
        });
    } catch (error: unknown) {
        const message =
            error instanceof Error
                ? error.message
                : 'Failed to retrieve donor profile';

        res.status(500).json({ error: message });
    }
};

// ====================== CREATE DONOR PROFILE ======================

export const createDonorProfileHandler = async (
    req: AuthRequest,
    res: Response<any, AuthLocals>,
): Promise<void> => {
    try {
        const customUserId = res.locals.currentUser.user.customUserId;

        const profile = await createDonorProfile(
            customUserId,
            req.body
        );

        res.status(201).json({
            message: 'Donor profile created successfully',
            profile,
            profileCompleted: true
        });
    } catch (error: unknown) {
        const message =
            error instanceof Error
                ? error.message
                : 'Failed to create donor profile';

        const status =
            message === 'User not found' ? 404 :
            message === 'Donor profile already exists' ? 409 :
            message.startsWith('Only donor') ? 403 :
            400;

        res.status(status).json({ error: message });
    }
};

// ====================== UPDATE DONOR PROFILE ======================

export const updateDonorProfileHandler = async (
    req: AuthRequest,
    res: Response<any, AuthLocals>,
): Promise<void> => {
    try {
        const customUserId = res.locals.currentUser.user.customUserId;

        const profile = await updateDonorProfile(
            customUserId,
            req.body
        );

        res.status(200).json({
            message: 'Donor profile updated successfully',
            profile,
            profileCompleted: true
        });
    } catch (error: unknown) {
        const message =
            error instanceof Error
                ? error.message
                : 'Failed to update donor profile';

        const status =
            message === 'Donor profile not found' ? 404 :
            message.startsWith('Only donor') ? 403 :
            400;

        res.status(status).json({ error: message });
    }
};

// ====================== GET DONOR PROFILE STATUS ======================

export const getDonorProfileStatusHandler = async (
    req: Request,
    res: Response<any, AuthLocals>,
): Promise<void> => {
    try {
        const customUserId = res.locals.currentUser.user.customUserId;

        const result = await getDonorProfileStatus(customUserId);

        res.status(200).json(result);
    } catch (error: unknown) {
        const message =
            error instanceof Error
                ? error.message
                : 'Failed to retrieve donor profile status';

        const status = message === 'User not found' ? 404 : 500;

        res.status(status).json({ error: message });
    }
};

// ====================== GET DONOR DELIVERIES ======================

export const getDonorDeliveriesHandler = async (
    req: Request,
    res: Response<any, AuthLocals>,
): Promise<void> => {
    try {
        const customUserId = res.locals.currentUser.user.customUserId;

        const deliveries = await getDonorDeliveries(customUserId);

        res.status(200).json({ deliveries });
    } catch (error: unknown) {
        const message =
            error instanceof Error
                ? error.message
                : 'Failed to retrieve deliveries';

        const status = message === 'Donor not found' ? 404 : 500;

        res.status(status).json({ error: message });
    }
};
