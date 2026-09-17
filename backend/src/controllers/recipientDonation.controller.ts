import { Request, Response } from 'express';
import { AuthLocals } from '../middleware/auth.middleware';
import {
    getAvailableRecipientDonations,
    getRecipientDonationById,
    RecipientDonationAvailability
} from '../services/recipientDonation.service';

const isAvailability = (
    value: string
): value is RecipientDonationAvailability => {
    return (
        value === 'available' ||
        value === 'unavailable' ||
        value === 'all'
    );
};

export const browseDonations = async (
    req: Request,
    res: Response<any, AuthLocals>
): Promise<void> => {
    try {
        const category =
            typeof req.query.category === 'string'
                ? req.query.category.trim()
                : undefined;

        const location =
            typeof req.query.location === 'string'
                ? req.query.location.trim()
                : undefined;

        const availabilityQuery =
            typeof req.query.availability === 'string'
                ? req.query.availability.trim().toLowerCase()
                : 'available';

        if (!isAvailability(availabilityQuery)) {
            res.status(400).json({
                error:
                    'Invalid availability filter. Use available, unavailable, or all.'
            });

            return;
        }

        const donations =
            await getAvailableRecipientDonations({
                category: category || undefined,
                location: location || undefined,
                availability: availabilityQuery
            });

        res.status(200).json({
            message:
                'Food donations fetched successfully',

            count: donations.length,

            filters: {
                category: category || null,
                location: location || null,
                availability: availabilityQuery
            },

            donations
        });
    } catch (error: any) {
        res.status(500).json({
            error: error.message
        });
    }
};

export const getDonationDetails = async (
    req: Request<{ id: string }>,
    res: Response<any, AuthLocals>
): Promise<void> => {
    try {
        const donation =
            await getRecipientDonationById(
                req.params.id
            );

        res.status(200).json({
            message:
                'Food donation details fetched successfully',

            donation
        });
    } catch (error: any) {
        if (
            error.message ===
            'Food donation not found'
        ) {
            res.status(404).json({
                error: error.message
            });

            return;
        }

        res.status(500).json({
            error: error.message
        });
    }
};