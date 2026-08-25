import { beforeEach, describe, expect, it, vi } from 'vitest';

const donationServiceMocks = vi.hoisted(() => ({
    getPendingDonations: vi.fn(),
    getDonationById: vi.fn(),
    approveDonation: vi.fn(),
    rejectDonation: vi.fn(),
    createDonation: vi.fn(),
    getAllDonations: vi.fn()
}));

vi.mock('../src/services/donation.service', () => ({
    getPendingDonations: donationServiceMocks.getPendingDonations,
    getDonationById: donationServiceMocks.getDonationById,
    approveDonation: donationServiceMocks.approveDonation,
    rejectDonation: donationServiceMocks.rejectDonation,
    createDonation: donationServiceMocks.createDonation,
    getAllDonations: donationServiceMocks.getAllDonations
}));

import {
    approveDonationHandler,
    getDonationByIdHandler,
    getPendingDonationsHandler,
    rejectDonationHandler
} from '../src/controllers/donation.controller';

describe('donation controller', () => {
    beforeEach(() => {
        vi.clearAllMocks();
    });

    const createMockResponse = () => {
        const res: any = {
            locals: {
                currentUser: {
                    user: {
                        customUserId: 'N1',
                        email: 'ngo@example.com',
                        roleCode: 'N'
                    }
                }
            },
            status: vi.fn().mockReturnThis(),
            json: vi.fn().mockReturnThis()
        };
        return res;
    };

    describe('getPendingDonationsHandler', () => {
        it('returns 200 and list of pending donations', async () => {
            const mockList = [
                { id: '1', title: 'Food Item 1', status: 'PENDING' },
                { id: '2', title: 'Food Item 2', status: 'PENDING' }
            ];
            donationServiceMocks.getPendingDonations.mockResolvedValue(mockList);

            const req: any = {};
            const res = createMockResponse();

            await getPendingDonationsHandler(req, res);

            expect(res.status).toHaveBeenCalledWith(200);
            expect(res.json).toHaveBeenCalledWith({
                message: 'Pending donations fetched successfully',
                count: 2,
                donations: mockList
            });
        });
    });

    describe('getDonationByIdHandler', () => {
        it('returns 200 and donation details when found', async () => {
            const mockDonation = { id: 'don-1', title: 'Food Item 1', status: 'PENDING' };
            donationServiceMocks.getDonationById.mockResolvedValue(mockDonation);

            const req: any = { params: { id: 'don-1' } };
            const res = createMockResponse();

            await getDonationByIdHandler(req, res);

            expect(res.status).toHaveBeenCalledWith(200);
            expect(res.json).toHaveBeenCalledWith({
                message: 'Donation details fetched successfully',
                donation: mockDonation
            });
        });

        it('returns 404 when donation is not found', async () => {
            donationServiceMocks.getDonationById.mockRejectedValue(new Error('Donation not found'));

            const req: any = { params: { id: 'nonexistent' } };
            const res = createMockResponse();

            await getDonationByIdHandler(req, res);

            expect(res.status).toHaveBeenCalledWith(404);
            expect(res.json).toHaveBeenCalledWith({ error: 'Donation not found' });
        });
    });

    describe('approveDonationHandler', () => {
        it('returns 200 and approved donation on success', async () => {
            const approvedDonation = {
                id: 'don-1',
                title: 'Food Item 1',
                status: 'APPROVED',
                reviewedBy: 'N1'
            };
            donationServiceMocks.approveDonation.mockResolvedValue(approvedDonation);

            const req: any = { params: { id: 'don-1' } };
            const res = createMockResponse();

            await approveDonationHandler(req, res);

            expect(donationServiceMocks.approveDonation).toHaveBeenCalledWith('don-1', 'N1');
            expect(res.status).toHaveBeenCalledWith(200);
            expect(res.json).toHaveBeenCalledWith({
                message: 'Food donation approved successfully',
                donation: approvedDonation
            });
        });

        it('returns 400 when donation is not in pending status', async () => {
            donationServiceMocks.approveDonation.mockRejectedValue(
                new Error("Cannot approve donation with status 'APPROVED'. Only pending donations can be approved.")
            );

            const req: any = { params: { id: 'don-1' } };
            const res = createMockResponse();

            await approveDonationHandler(req, res);

            expect(res.status).toHaveBeenCalledWith(400);
            expect(res.json).toHaveBeenCalledWith({
                error: "Cannot approve donation with status 'APPROVED'. Only pending donations can be approved."
            });
        });
    });

    describe('rejectDonationHandler', () => {
        it('returns 200 and rejected donation when reason is provided', async () => {
            const rejectedDonation = {
                id: 'don-1',
                title: 'Food Item 1',
                status: 'REJECTED',
                rejectionReason: 'Damaged packaging',
                reviewedBy: 'N1'
            };
            donationServiceMocks.rejectDonation.mockResolvedValue(rejectedDonation);

            const req: any = {
                params: { id: 'don-1' },
                body: { rejectionReason: 'Damaged packaging' }
            };
            const res = createMockResponse();

            await rejectDonationHandler(req, res);

            expect(donationServiceMocks.rejectDonation).toHaveBeenCalledWith(
                'don-1',
                'Damaged packaging',
                'N1'
            );
            expect(res.status).toHaveBeenCalledWith(200);
            expect(res.json).toHaveBeenCalledWith({
                message: 'Food donation rejected successfully',
                donation: rejectedDonation
            });
        });

        it('returns 400 validation error when rejectionReason is missing', async () => {
            const req: any = {
                params: { id: 'don-1' },
                body: {}
            };
            const res = createMockResponse();

            await rejectDonationHandler(req, res);

            expect(res.status).toHaveBeenCalledWith(400);
            expect(res.json).toHaveBeenCalledWith({
                errors: ['Rejection reason is required.']
            });
        });

        it('returns 400 when donation is not pending', async () => {
            donationServiceMocks.rejectDonation.mockRejectedValue(
                new Error("Cannot reject donation with status 'APPROVED'. Only pending donations can be rejected.")
            );

            const req: any = {
                params: { id: 'don-1' },
                body: { rejectionReason: 'Food spoiled' }
            };
            const res = createMockResponse();

            await rejectDonationHandler(req, res);

            expect(res.status).toHaveBeenCalledWith(400);
            expect(res.json).toHaveBeenCalledWith({
                error: "Cannot reject donation with status 'APPROVED'. Only pending donations can be rejected."
            });
        });
    });
});
