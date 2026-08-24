import { Request, Response } from 'express';
import { createDonation } from '../services/donation.service';
import { AuthLocals } from '../middleware/auth.middleware';
import { validateDonationInput } from '../validators/donation.validator';
import { uploadImageToCloudinary } from '../services/cloudinary.service';

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
            error: error.message
        });
    }
};