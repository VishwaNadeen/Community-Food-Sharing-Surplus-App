import { Request, Response } from 'express';
import { AuthLocals } from '../middleware/auth.middleware';
import {
    approveDonation,
    createDonation,
    getAllDonations,
    getDonationById,
    getPendingDonations,
    rejectDonation
} from '../services/donation.service';
import {
    validateCreateDonationInput,
    validateRejectDonationInput
} from '../validators/donation.validator';

// GET /donations/pending - View pending donations (NGO Coordinator)
export const getPendingDonationsHandler = async (
    req: Request,
    res: Response<any, AuthLocals>
): Promise<void> => {
    try {
        const donations = await getPendingDonations();
        res.status(200).json({
            message: 'Pending donations fetched successfully',
            count: donations.length,
            donations
        });
    } catch (error: any) {
        res.status(500).json({ error: error.message });
    }
};

// GET /donations/:id - View donation details
export const getDonationByIdHandler = async (
    req: Request,
    res: Response<any, AuthLocals>
): Promise<void> => {
    try {
        const id = Array.isArray(req.params.id) ? req.params.id[0] : String(req.params.id);
        const donation = await getDonationById(id);
        res.status(200).json({
            message: 'Donation details fetched successfully',
            donation
        });
    } catch (error: any) {
        if (error.message === 'Donation not found') {
            res.status(404).json({ error: error.message });
            return;
        }
        res.status(500).json({ error: error.message });
    }
};

// PATCH/POST /donations/:id/approve - Approve food donation (NGO Coordinator)
export const approveDonationHandler = async (
    req: Request,
    res: Response<any, AuthLocals>
): Promise<void> => {
    try {
        const id = Array.isArray(req.params.id) ? req.params.id[0] : String(req.params.id);
        const coordinatorCustomUserId = res.locals.currentUser.user.customUserId;

        const updatedDonation = await approveDonation(id, coordinatorCustomUserId);
        res.status(200).json({
            message: 'Food donation approved successfully',
            donation: updatedDonation
        });
    } catch (error: any) {
        if (error.message === 'Donation not found') {
            res.status(404).json({ error: error.message });
            return;
        }
        if (error.message.includes('Cannot approve donation with status')) {
            res.status(400).json({ error: error.message });
            return;
        }
        res.status(500).json({ error: error.message });
    }
};

// PATCH/POST /donations/:id/reject - Reject food donation with reason (NGO Coordinator)
export const rejectDonationHandler = async (
    req: Request,
    res: Response<any, AuthLocals>
): Promise<void> => {
    try {
        const id = Array.isArray(req.params.id) ? req.params.id[0] : String(req.params.id);
        const validationErrors = validateRejectDonationInput(req.body);
        if (validationErrors.length > 0) {
            res.status(400).json({ errors: validationErrors });
            return;
        }

        const { rejectionReason } = req.body;
        const coordinatorCustomUserId = res.locals.currentUser.user.customUserId;

        const updatedDonation = await rejectDonation(id, rejectionReason, coordinatorCustomUserId);
        res.status(200).json({
            message: 'Food donation rejected successfully',
            donation: updatedDonation
        });
    } catch (error: any) {
        if (error.message === 'Donation not found') {
            res.status(404).json({ error: error.message });
            return;
        }
        if (error.message.includes('Cannot reject donation with status') || error.message === 'Rejection reason is required') {
            res.status(400).json({ error: error.message });
            return;
        }
        res.status(500).json({ error: error.message });
    }
};

// POST /donations - Submit a new food donation
export const createDonationHandler = async (
    req: Request,
    res: Response<any, AuthLocals>
): Promise<void> => {
    try {
        const validationErrors = validateCreateDonationInput(req.body);
        if (validationErrors.length > 0) {
            res.status(400).json({ errors: validationErrors });
            return;
        }

        const currentUser = res.locals.currentUser.user;
        const donation = await createDonation(req.body, {
            customUserId: currentUser.customUserId,
            email: currentUser.email
        });

        res.status(201).json({
            message: 'Food donation submitted successfully',
            donation
        });
    } catch (error: any) {
        res.status(500).json({ error: error.message });
    }
};

// GET /donations - View all donations with optional query filters
export const getAllDonationsHandler = async (
    req: Request,
    res: Response<any, AuthLocals>
): Promise<void> => {
    try {
        const status = req.query.status as string | undefined;
        const donorId = req.query.donorId as string | undefined;

        const donations = await getAllDonations({ status, donorId });
        res.status(200).json({
            message: 'Donations fetched successfully',
            count: donations.length,
            donations
        });
    } catch (error: any) {
        res.status(500).json({ error: error.message });
    }
};
