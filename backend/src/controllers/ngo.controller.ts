import { Request, Response } from 'express';
import { AuthLocals } from '../middleware/auth.middleware';
import {
    approveDonation,
    getAllDonations,
    getDonationById,
    getPendingDonations,
    rejectDonation,
    approveFoodRequest,
    getAllFoodRequests,
    getFoodRequestById,
    getPendingFoodRequests,
    rejectFoodRequest
} from '../services/ngo.service';
import { validateRejectDonationInput } from '../validators/donation.validator';
import { validateRejectFoodRequestInput } from '../validators/foodRequest.validator';

// FOOD DONATION REVIEW HANDLERS

// GET /ngo/donations/pending - View pending donations
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

// GET /ngo/donations/:id - View donation details
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

// PATCH/POST /ngo/donations/:id/approve - Approve food donation
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

// PATCH/POST /ngo/donations/:id/reject - Reject food donation with reason
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

// GET /ngo/donations - View all donations (supports status filter)
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

// RECIPIENT FOOD REQUEST REVIEW HANDLERS

// GET /ngo/requests/pending - View pending food requests
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

// GET /ngo/requests/:id - View food request details
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

// PATCH/POST /ngo/requests/:id/approve - Approve food request
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

// PATCH/POST /ngo/requests/:id/reject - Reject food request with reason
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

// GET /ngo/requests - View all food requests (supports status filter)
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

// FOOD MATCH HANDLERS (CFSASA-60)

import { generateFoodMatches, getFoodMatches } from '../services/matching.service';

// POST /ngo/matches/generate - Run the matching engine
export const generateMatchesHandler = async (
    req: Request,
    res: Response<any, AuthLocals>
): Promise<void> => {
    try {
        const matches = await generateFoodMatches();
        res.status(200).json({
            message: `Matching complete. ${matches.length} match(es) found.`,
            count: matches.length,
            matches
        });
    } catch (error: any) {
        res.status(500).json({ error: error.message });
    }
};

// GET /ngo/matches - Retrieve all stored matches (with donation + request details)
export const getMatchesHandler = async (
    req: Request,
    res: Response<any, AuthLocals>
): Promise<void> => {
    try {
        const matches = await getFoodMatches();
        res.status(200).json({
            message: 'Matches fetched successfully',
            count: matches.length,
            matches
        });
    } catch (error: any) {
        res.status(500).json({ error: error.message });
    }
};

