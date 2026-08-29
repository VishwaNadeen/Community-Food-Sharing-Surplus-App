import { beforeEach, describe, expect, it, vi } from 'vitest';

const ngoServiceMocks = vi.hoisted(() => ({
    getPendingDonations: vi.fn(),
    getDonationById: vi.fn(),
    approveDonation: vi.fn(),
    rejectDonation: vi.fn(),
    getAllDonations: vi.fn(),
    getPendingFoodRequests: vi.fn(),
    getFoodRequestById: vi.fn(),
    approveFoodRequest: vi.fn(),
    rejectFoodRequest: vi.fn(),
    getAllFoodRequests: vi.fn()
}));

vi.mock('../src/services/ngo.service', () => ({
    getPendingDonations: ngoServiceMocks.getPendingDonations,
    getDonationById: ngoServiceMocks.getDonationById,
    approveDonation: ngoServiceMocks.approveDonation,
    rejectDonation: ngoServiceMocks.rejectDonation,
    getAllDonations: ngoServiceMocks.getAllDonations,
    getPendingFoodRequests: ngoServiceMocks.getPendingFoodRequests,
    getFoodRequestById: ngoServiceMocks.getFoodRequestById,
    approveFoodRequest: ngoServiceMocks.approveFoodRequest,
    rejectFoodRequest: ngoServiceMocks.rejectFoodRequest,
    getAllFoodRequests: ngoServiceMocks.getAllFoodRequests
}));

import {
    approveDonationHandler,
    approveFoodRequestHandler,
    getDonationByIdHandler,
    getFoodRequestByIdHandler,
    getPendingDonationsHandler,
    getPendingFoodRequestsHandler,
    rejectDonationHandler,
    rejectFoodRequestHandler
} from '../src/controllers/ngo.controller';

describe('ngo controller (/ngo)', () => {
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

    describe('Donations Review Handlers', () => {
        it('getPendingDonationsHandler returns 200 and list', async () => {
            const list = [{ id: '1', title: 'Food Item 1', status: 'PENDING' }];
            ngoServiceMocks.getPendingDonations.mockResolvedValue(list);

            const req: any = {};
            const res = createMockResponse();

            await getPendingDonationsHandler(req, res);

            expect(res.status).toHaveBeenCalledWith(200);
            expect(res.json).toHaveBeenCalledWith({
                message: 'Pending donations fetched successfully',
                count: 1,
                donations: list
            });
        });

        it('approveDonationHandler approves donation', async () => {
            const approved = { id: 'don-1', status: 'APPROVED', reviewedBy: 'N1' };
            ngoServiceMocks.approveDonation.mockResolvedValue(approved);

            const req: any = { params: { id: 'don-1' } };
            const res = createMockResponse();

            await approveDonationHandler(req, res);

            expect(ngoServiceMocks.approveDonation).toHaveBeenCalledWith('don-1', 'N1');
            expect(res.status).toHaveBeenCalledWith(200);
            expect(res.json).toHaveBeenCalledWith({
                message: 'Food donation approved successfully',
                donation: approved
            });
        });

        it('rejectDonationHandler rejects donation with reason', async () => {
            const rejected = { id: 'don-1', status: 'REJECTED', rejectionReason: 'Damaged' };
            ngoServiceMocks.rejectDonation.mockResolvedValue(rejected);

            const req: any = { params: { id: 'don-1' }, body: { rejectionReason: 'Damaged packaging' } };
            const res = createMockResponse();

            await rejectDonationHandler(req, res);

            expect(ngoServiceMocks.rejectDonation).toHaveBeenCalledWith('don-1', 'Damaged packaging', 'N1');
            expect(res.status).toHaveBeenCalledWith(200);
        });
    });

    describe('Requests Review Handlers', () => {
        it('getPendingFoodRequestsHandler returns 200 and list', async () => {
            const list = [{ id: 'req-1', foodItem: 'Meals', status: 'PENDING' }];
            ngoServiceMocks.getPendingFoodRequests.mockResolvedValue(list);

            const req: any = {};
            const res = createMockResponse();

            await getPendingFoodRequestsHandler(req, res);

            expect(res.status).toHaveBeenCalledWith(200);
            expect(res.json).toHaveBeenCalledWith({
                message: 'Pending food requests fetched successfully',
                count: 1,
                requests: list
            });
        });

        it('approveFoodRequestHandler approves request', async () => {
            const approved = { id: 'req-1', status: 'APPROVED', reviewedBy: 'N1' };
            ngoServiceMocks.approveFoodRequest.mockResolvedValue(approved);

            const req: any = { params: { id: 'req-1' } };
            const res = createMockResponse();

            await approveFoodRequestHandler(req, res);

            expect(ngoServiceMocks.approveFoodRequest).toHaveBeenCalledWith('req-1', 'N1');
            expect(res.status).toHaveBeenCalledWith(200);
        });

        it('rejectFoodRequestHandler rejects request with reason', async () => {
            const rejected = { id: 'req-1', status: 'REJECTED', rejectionReason: 'Quota full' };
            ngoServiceMocks.rejectFoodRequest.mockResolvedValue(rejected);

            const req: any = { params: { id: 'req-1' }, body: { rejectionReason: 'Quota full for this week' } };
            const res = createMockResponse();

            await rejectFoodRequestHandler(req, res);

            expect(ngoServiceMocks.rejectFoodRequest).toHaveBeenCalledWith('req-1', 'Quota full for this week', 'N1');
            expect(res.status).toHaveBeenCalledWith(200);
        });
    });
});
