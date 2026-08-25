import { beforeEach, describe, expect, it, vi } from 'vitest';

const foodRequestServiceMocks = vi.hoisted(() => ({
    getPendingFoodRequests: vi.fn(),
    getFoodRequestById: vi.fn(),
    approveFoodRequest: vi.fn(),
    rejectFoodRequest: vi.fn(),
    createFoodRequest: vi.fn(),
    getAllFoodRequests: vi.fn()
}));

vi.mock('../src/services/foodRequest.service', () => ({
    getPendingFoodRequests: foodRequestServiceMocks.getPendingFoodRequests,
    getFoodRequestById: foodRequestServiceMocks.getFoodRequestById,
    approveFoodRequest: foodRequestServiceMocks.approveFoodRequest,
    rejectFoodRequest: foodRequestServiceMocks.rejectFoodRequest,
    createFoodRequest: foodRequestServiceMocks.createFoodRequest,
    getAllFoodRequests: foodRequestServiceMocks.getAllFoodRequests
}));

import {
    approveFoodRequestHandler,
    getFoodRequestByIdHandler,
    getPendingFoodRequestsHandler,
    rejectFoodRequestHandler
} from '../src/controllers/foodRequest.controller';

describe('food request controller', () => {
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

    describe('getPendingFoodRequestsHandler', () => {
        it('returns 200 and list of pending food requests', async () => {
            const mockList = [
                { id: '1', foodItem: 'Bread', quantityRequested: '2', status: 'PENDING' },
                { id: '2', foodItem: 'Rice', quantityRequested: '5 kg', status: 'PENDING' }
            ];
            foodRequestServiceMocks.getPendingFoodRequests.mockResolvedValue(mockList);

            const req: any = {};
            const res = createMockResponse();

            await getPendingFoodRequestsHandler(req, res);

            expect(res.status).toHaveBeenCalledWith(200);
            expect(res.json).toHaveBeenCalledWith({
                message: 'Pending food requests fetched successfully',
                count: 2,
                requests: mockList
            });
        });
    });

    describe('getFoodRequestByIdHandler', () => {
        it('returns 200 and request details with recipient info and food item', async () => {
            const mockRequest = {
                id: 'req-1',
                recipientId: 'R1',
                recipientName: 'Alice',
                foodItem: 'Soup',
                quantityRequested: '2 bowls',
                status: 'PENDING'
            };
            foodRequestServiceMocks.getFoodRequestById.mockResolvedValue(mockRequest);

            const req: any = { params: { id: 'req-1' } };
            const res = createMockResponse();

            await getFoodRequestByIdHandler(req, res);

            expect(res.status).toHaveBeenCalledWith(200);
            expect(res.json).toHaveBeenCalledWith({
                message: 'Food request details fetched successfully',
                request: mockRequest
            });
        });

        it('returns 404 when request is not found', async () => {
            foodRequestServiceMocks.getFoodRequestById.mockRejectedValue(new Error('Food request not found'));

            const req: any = { params: { id: 'req-nonexistent' } };
            const res = createMockResponse();

            await getFoodRequestByIdHandler(req, res);

            expect(res.status).toHaveBeenCalledWith(404);
            expect(res.json).toHaveBeenCalledWith({ error: 'Food request not found' });
        });
    });

    describe('approveFoodRequestHandler', () => {
        it('returns 200 and approved request on success', async () => {
            const approvedRequest = {
                id: 'req-1',
                foodItem: 'Rice',
                status: 'APPROVED',
                reviewedBy: 'N1'
            };
            foodRequestServiceMocks.approveFoodRequest.mockResolvedValue(approvedRequest);

            const req: any = { params: { id: 'req-1' } };
            const res = createMockResponse();

            await approveFoodRequestHandler(req, res);

            expect(foodRequestServiceMocks.approveFoodRequest).toHaveBeenCalledWith('req-1', 'N1');
            expect(res.status).toHaveBeenCalledWith(200);
            expect(res.json).toHaveBeenCalledWith({
                message: 'Food request approved successfully',
                request: approvedRequest
            });
        });

        it('returns 400 when request is not pending', async () => {
            foodRequestServiceMocks.approveFoodRequest.mockRejectedValue(
                new Error("Cannot approve request with status 'APPROVED'. Only pending requests can be approved.")
            );

            const req: any = { params: { id: 'req-1' } };
            const res = createMockResponse();

            await approveFoodRequestHandler(req, res);

            expect(res.status).toHaveBeenCalledWith(400);
            expect(res.json).toHaveBeenCalledWith({
                error: "Cannot approve request with status 'APPROVED'. Only pending requests can be approved."
            });
        });
    });

    describe('rejectFoodRequestHandler', () => {
        it('returns 200 and rejected request when reason is provided', async () => {
            const rejectedRequest = {
                id: 'req-1',
                foodItem: 'Rice',
                status: 'REJECTED',
                rejectionReason: 'Exceeds household limit',
                reviewedBy: 'N1'
            };
            foodRequestServiceMocks.rejectFoodRequest.mockResolvedValue(rejectedRequest);

            const req: any = {
                params: { id: 'req-1' },
                body: { rejectionReason: 'Exceeds household limit' }
            };
            const res = createMockResponse();

            await rejectFoodRequestHandler(req, res);

            expect(foodRequestServiceMocks.rejectFoodRequest).toHaveBeenCalledWith(
                'req-1',
                'Exceeds household limit',
                'N1'
            );
            expect(res.status).toHaveBeenCalledWith(200);
            expect(res.json).toHaveBeenCalledWith({
                message: 'Food request rejected successfully',
                request: rejectedRequest
            });
        });

        it('returns 400 validation error when rejectionReason is missing', async () => {
            const req: any = {
                params: { id: 'req-1' },
                body: {}
            };
            const res = createMockResponse();

            await rejectFoodRequestHandler(req, res);

            expect(res.status).toHaveBeenCalledWith(400);
            expect(res.json).toHaveBeenCalledWith({
                errors: ['Rejection reason is required.']
            });
        });

        it('returns 400 when request is not pending', async () => {
            foodRequestServiceMocks.rejectFoodRequest.mockRejectedValue(
                new Error("Cannot reject request with status 'REJECTED'. Only pending requests can be rejected.")
            );

            const req: any = {
                params: { id: 'req-1' },
                body: { rejectionReason: 'Out of stock' }
            };
            const res = createMockResponse();

            await rejectFoodRequestHandler(req, res);

            expect(res.status).toHaveBeenCalledWith(400);
            expect(res.json).toHaveBeenCalledWith({
                error: "Cannot reject request with status 'REJECTED'. Only pending requests can be rejected."
            });
        });
    });
});
