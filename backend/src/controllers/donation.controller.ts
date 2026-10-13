
import { Request, Response } from 'express';
import 'multer';
import {
    createDonation,
    getDonationsByDonor,
    updateDonation,
    cancelDonation
} from '../services/donation.service';
import { AuthLocals } from '../middleware/auth.middleware';
import {
    validateDonationInput,
    validateDonationUpdateInput
} from '../validators/donation.validator';
import { uploadImageToCloudinary } from '../services/cloudinary.service';

/**
 * Multipart form fields arrive as strings.
 * Convert quantity to a number before validation and saving.
 */
const normalizeDonationQuantity = (body: any): void => {
    if (body.quantity !== undefined && body.quantity !== null) {
        const value = String(body.quantity).trim();

        body.quantity = value === '' ? Number.NaN : Number(value);
    }
};

export const create = async (
    req: Request,
    res: Response<any, AuthLocals>
): Promise<void> => {
    try {
        const currentUser = res.locals.currentUser.user;

        if (currentUser.roleCode !== 'D') {
            res.status(403).json({
                error: 'Only donors can create food donations'
            });
            return;
        }

        normalizeDonationQuantity(req.body);

        const validationErrors = validateDonationInput(req.body);

        if (validationErrors.length > 0) {
            res.status(400).json({
                errors: validationErrors
            });
            return;
        }

        let imageUrl: string | undefined;

        if (req.file) {
            imageUrl = await uploadImageToCloudinary(req.file.buffer);
        }

        const donation = await createDonation(
            currentUser.customUserId,
            req.body,
            imageUrl
        );

        res.status(201).json({
            message: 'Food donation created successfully',
            donation
        });
    } catch (error: any) {
        res.status(500).json({
            error: error.message || 'Failed to create donation'
        });
    }
};

export const getMyDonations = async (
    req: Request,
    res: Response<any, AuthLocals>
): Promise<void> => {
    try {
        const currentUser = res.locals.currentUser.user;

        if (currentUser.roleCode !== 'D') {
            res.status(403).json({
                error: 'Only donors can view their donations'
            });
            return;
        }

        const donations = await getDonationsByDonor(
            currentUser.customUserId
        );

        res.status(200).json({
            donations
        });
    } catch (error: any) {
        res.status(500).json({
            error: error.message || 'Failed to fetch donations'
        });
    }
};

export const update = async (
    req: Request<{ id: string }>,
    res: Response<any, AuthLocals>
): Promise<void> => {
    try {
        const currentUser = res.locals.currentUser.user;

        if (currentUser.roleCode !== 'D') {
            res.status(403).json({
                error: 'Only donors can edit food donations'
            });
            return;
        }

        normalizeDonationQuantity(req.body);

        const validationErrors = validateDonationUpdateInput(req.body);

        if (validationErrors.length > 0) {
            res.status(400).json({
                errors: validationErrors
            });
            return;
        }

        let imageUrl: string | undefined;

        if (req.file) {
            imageUrl = await uploadImageToCloudinary(req.file.buffer);
        }

        const donation = await updateDonation(
            req.params.id,
            currentUser.customUserId,
            req.body,
            imageUrl
        );

        res.status(200).json({
            message: 'Food donation updated successfully',
            donation
        });
    } catch (error: any) {
        if (error.message === 'Donation not found') {
            res.status(404).json({
                error: error.message
            });
            return;
        }

        if (
            error.message === 'You are not allowed to edit this donation' ||
            error.message === 'Only available donations can be edited'
        ) {
            res.status(403).json({
                error: error.message
            });
            return;
        }

        res.status(500).json({
            error: error.message || 'Failed to update donation'
        });
    }
};

export const cancel = async (
    req: Request<{ id: string }>,
    res: Response<any, AuthLocals>
): Promise<void> => {
    try {
        const currentUser = res.locals.currentUser.user;

        if (currentUser.roleCode !== 'D') {
            res.status(403).json({
                error: 'Only donors can cancel food donations'
            });
            return;
        }

        const donation = await cancelDonation(
            req.params.id,
            currentUser.customUserId
        );

        res.status(200).json({
            message: 'Food donation cancelled successfully',
            donation
        });
    } catch (error: any) {
        if (error.message === 'Donation not found') {
            res.status(404).json({
                error: error.message
            });
            return;
        }

        if (
            error.message === 'You are not allowed to cancel this donation' ||
            error.message === 'Only available donations can be cancelled'
        ) {
            res.status(403).json({
                error: error.message
            });
            return;
        }

        res.status(500).json({
            error: error.message || 'Failed to cancel donation'
        });
    }
};
