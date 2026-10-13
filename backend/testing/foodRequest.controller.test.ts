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
    createFoodRequestHandler,
    getAllFoodRequestsHandler,
    getFoodRequestByIdHandler,
    getPendingFoodRequestsHandler,
    rejectFoodRequestHandler
} from '../src/controllers/foodRequest.controller';

describe('food request controller (/requests)', () => {
    beforeEach(() => {
        vi.clearAllMocks();
    });

    const createMockResponse = (role = 'N', customUserId = 'N1') => {
        const res: any = {
            locals: {
                currentUser: {
                    user: {
                        customUserId,
                        email: 'user@example.com',
                        roleCode: role
                    }
                }
            },
            status: vi.fn().mockReturnThis(),
            json: vi.fn().mockReturnThis()
        };
        return res;
    };

    it('getPendingFoodRequestsHandler returns 200 with pending requests', async () => {
        const list = [{ id: 'req-1', status: 'PENDING', foodItem: 'Bread' }];
        foodRequestServiceMocks.getPendingFoodRequests.mockResolvedValue(list);

        const req: any = {};
        const res = createMockResponse('N', 'N1');

        await getPendingFoodRequestsHandler(req, res);

        expect(res.status).toHaveBeenCalledWith(200);
        expect(res.json).toHaveBeenCalledWith({
            message: 'Pending food requests fetched successfully',
            count: 1,
            requests: list
        });
    });

    it('getFoodRequestByIdHandler returns request details', async () => {
        const request = { id: 'req-1', status: 'PENDING', foodItem: 'Bread' };
        foodRequestServiceMocks.getFoodRequestById.mockResolvedValue(request);

        const req: any = { params: { id: 'req-1' } };
        const res = createMockResponse();

        await getFoodRequestByIdHandler(req, res);

        expect(res.status).toHaveBeenCalledWith(200);
        expect(res.json).toHaveBeenCalledWith({
            message: 'Food request details fetched successfully',
            request
        });
    });

    it('getFoodRequestByIdHandler returns 404 when not found', async () => {
        foodRequestServiceMocks.getFoodRequestById.mockRejectedValue(new Error('Food request not found'));

        const req: any = { params: { id: 'missing' } };
        const res = createMockResponse();

        await getFoodRequestByIdHandler(req, res);

        expect(res.status).toHaveBeenCalledWith(404);
        expect(res.json).toHaveBeenCalledWith({ error: 'Food request not found' });
    });

    it('approveFoodRequestHandler approves pending request', async () => {
        const approved = { id: 'req-1', status: 'APPROVED', reviewedBy: 'N1' };
        foodRequestServiceMocks.approveFoodRequest.mockResolvedValue(approved);

        const req: any = { params: { id: 'req-1' } };
        const res = createMockResponse('N', 'N1');

        await approveFoodRequestHandler(req, res);

        expect(foodRequestServiceMocks.approveFoodRequest).toHaveBeenCalledWith('req-1', 'N1');
        expect(res.status).toHaveBeenCalledWith(200);
        expect(res.json).toHaveBeenCalledWith({
            message: 'Food request approved successfully',
            request: approved
        });
    });

    it('rejectFoodRequestHandler rejects pending request with reason', async () => {
        const rejected = { id: 'req-1', status: 'REJECTED', rejectionReason: 'Stock unavailable' };
        foodRequestServiceMocks.rejectFoodRequest.mockResolvedValue(rejected);

        const req: any = {
            params: { id: 'req-1' },
            body: { rejectionReason: 'Stock unavailable' }
        };
        const res = createMockResponse('N', 'N1');

        await rejectFoodRequestHandler(req, res);

        expect(foodRequestServiceMocks.rejectFoodRequest).toHaveBeenCalledWith('req-1', 'Stock unavailable', 'N1');
        expect(res.status).toHaveBeenCalledWith(200);
        expect(res.json).toHaveBeenCalledWith({
            message: 'Food request rejected successfully',
            request: rejected
        });
    });

    it('createFoodRequestHandler creates new recipient food request', async () => {
        const created = { id: 'req-1', status: 'PENDING', foodItem: 'Rice', quantityRequested: '5 kg' };
        foodRequestServiceMocks.createFoodRequest.mockResolvedValue(created);

        const req: any = {
            body: { foodItem: 'Rice', quantityRequested: '5 kg' }
        };
        const res = createMockResponse('R', 'R1');

        await createFoodRequestHandler(req, res);

        expect(foodRequestServiceMocks.createFoodRequest).toHaveBeenCalledWith(
            req.body,
            { customUserId: 'R1', email: 'user@example.com' }
        );
        expect(res.status).toHaveBeenCalledWith(201);
        expect(res.json).toHaveBeenCalledWith({
            message: 'Food request submitted successfully',
            request: created
        });
    });

    it('createFoodRequestHandler returns 400 when input validation fails', async () => {
        const req: any = {
            body: { foodItem: '' }
        };
        const res = createMockResponse('R', 'R1');

        await createFoodRequestHandler(req, res);

        expect(res.status).toHaveBeenCalledWith(400);
        expect(res.json).toHaveBeenCalledWith(expect.objectContaining({ errors: expect.any(Array) }));
    });

    it('getAllFoodRequestsHandler returns list with filters', async () => {
        const list = [{ id: 'req-1', status: 'PENDING' }];
        foodRequestServiceMocks.getAllFoodRequests.mockResolvedValue(list);

        const req: any = { query: { status: 'PENDING', recipientId: 'R1' } };
        const res = createMockResponse();

        await getAllFoodRequestsHandler(req, res);

        expect(foodRequestServiceMocks.getAllFoodRequests).toHaveBeenCalledWith({
            status: 'PENDING',
            recipientId: 'R1'
        });
        expect(res.status).toHaveBeenCalledWith(200);
        expect(res.json).toHaveBeenCalledWith({
            message: 'Food requests fetched successfully',
            count: 1,
            requests: list
        });
    });
});
