import { beforeEach, describe, expect, it, vi } from 'vitest';

const prismaMocks = vi.hoisted(() => ({
    findUnique: vi.fn(),
    findFirst: vi.fn(),
    findMany: vi.fn(),
    create: vi.fn(),
    update: vi.fn(),
    deliveryFindFirst: vi.fn(),
    deliveryCreate: vi.fn(),
    deliveryUpdateMany: vi.fn(),
    recipientFindUnique: vi.fn(),
    donationFindUnique: vi.fn()
}));

vi.mock('@prisma/client', () => ({
    PrismaClient: vi.fn().mockImplementation(() => ({
        foodRequest: {
            findUnique: prismaMocks.findUnique,
            findFirst: prismaMocks.findFirst,
            findMany: prismaMocks.findMany,
            create: prismaMocks.create,
            update: prismaMocks.update
        },
        delivery: {
            findFirst: prismaMocks.deliveryFindFirst,
            create: prismaMocks.deliveryCreate,
            updateMany: prismaMocks.deliveryUpdateMany
        },
        recipient: {
            findUnique: prismaMocks.recipientFindUnique
        },
        foodDonation: {
            findUnique: prismaMocks.donationFindUnique
        }
    }))
}));

import {
    approveFoodRequest,
    createFoodRequest,
    getFoodRequestById,
    getPendingFoodRequests,
    rejectFoodRequest
} from '../src/services/foodRequest.service';

describe('food request service', () => {
    beforeEach(() => {
        vi.clearAllMocks();
    });

    describe('getPendingFoodRequests', () => {
        it('returns all requests with status PENDING', async () => {
            const mockPendingRequests = [
                {
                    id: 'req-1',
                    customRequestId: 'RQ1',
                    recipientId: 'R1',
                    foodItem: 'Rice and Vegetables',
                    quantityRequested: '2 portions',
                    status: 'PENDING',
                    createdAt: new Date()
                },
                {
                    id: 'req-2',
                    customRequestId: 'RQ2',
                    recipientId: 'R2',
                    foodItem: 'Fresh Milk',
                    quantityRequested: '1 carton',
                    status: 'PENDING',
                    createdAt: new Date()
                }
            ];

            prismaMocks.findMany.mockResolvedValue(mockPendingRequests);

            const result = await getPendingFoodRequests();

            expect(prismaMocks.findMany).toHaveBeenCalledWith({
                where: { status: 'PENDING' },
                orderBy: { createdAt: 'desc' }
            });
            expect(result).toHaveLength(2);
            expect(result[0].status).toBe('PENDING');
        });
    });

    describe('getFoodRequestById', () => {
        it('returns full request details when found by id', async () => {
            const mockRequest = {
                id: 'req-123',
                customRequestId: 'RQ5',
                recipientId: 'R1',
                recipientName: 'John Doe',
                recipientContact: '+94770000000',
                foodItem: 'Canned Beans',
                quantityRequested: '5 cans',
                status: 'PENDING'
            };

            prismaMocks.findUnique.mockResolvedValue(mockRequest);

            const result = await getFoodRequestById('req-123');

            expect(prismaMocks.findUnique).toHaveBeenCalledWith({ where: { id: 'req-123' } });
            expect(result.id).toBe('req-123');
            expect(result.foodItem).toBe('Canned Beans');
            expect(result.recipientName).toBe('John Doe');
        });

        it('throws error when food request is not found', async () => {
            prismaMocks.findUnique.mockResolvedValue(null);

            await expect(getFoodRequestById('non-existent-id')).rejects.toThrow('Food request not found');
        });
    });

    describe('approveFoodRequest', () => {
        it('approves a pending request and updates audit info', async () => {
            const pendingRequest = {
                id: 'req-123',
                customRequestId: 'RQ1',
                recipientId: 'R1',
                foodItem: 'Bread',
                quantityRequested: '2 loaves',
                status: 'PENDING',
                reviewedBy: null,
                reviewedAt: null
            };

            const approvedRequest = {
                ...pendingRequest,
                status: 'APPROVED',
                rejectionReason: null,
                reviewedBy: 'N1',
                reviewedAt: new Date()
            };

            prismaMocks.findUnique.mockResolvedValue(pendingRequest);
            prismaMocks.update.mockResolvedValue(approvedRequest);

            const result = await approveFoodRequest('req-123', 'N1');

            expect(prismaMocks.update).toHaveBeenCalledWith({
                where: { id: 'req-123' },
                data: {
                    status: 'APPROVED',
                    rejectionReason: null,
                    reviewedBy: 'N1',
                    reviewedAt: expect.any(Date)
                }
            });
            expect(result.status).toBe('APPROVED');
            expect(result.reviewedBy).toBe('N1');
            expect(prismaMocks.deliveryCreate).toHaveBeenCalledWith({
                data: expect.objectContaining({
                    status: 'PENDING_ASSIGNMENT',
                    volunteerId: null,
                    recipientId: 'R1',
                    foodItem: 'Bread'
                })
            });
        });

        it('throws an error if food request is already approved', async () => {
            const alreadyApproved = {
                id: 'req-123',
                customRequestId: 'RQ1',
                foodItem: 'Bread',
                status: 'APPROVED'
            };

            prismaMocks.findUnique.mockResolvedValue(alreadyApproved);

            await expect(approveFoodRequest('req-123', 'N1')).rejects.toThrow(
                "Cannot approve request with status 'APPROVED'. Only pending requests can be approved."
            );
        });

        it('throws an error if food request is already rejected', async () => {
            const alreadyRejected = {
                id: 'req-123',
                customRequestId: 'RQ1',
                foodItem: 'Bread',
                status: 'REJECTED'
            };

            prismaMocks.findUnique.mockResolvedValue(alreadyRejected);

            await expect(approveFoodRequest('req-123', 'N1')).rejects.toThrow(
                "Cannot approve request with status 'REJECTED'. Only pending requests can be approved."
            );
        });
    });

    describe('rejectFoodRequest', () => {
        it('rejects a pending food request with reason and coordinator info', async () => {
            const pendingRequest = {
                id: 'req-123',
                customRequestId: 'RQ1',
                recipientId: 'R1',
                foodItem: 'Hot Meals',
                quantityRequested: '50 portions',
                status: 'PENDING'
            };

            const rejectedRequest = {
                ...pendingRequest,
                status: 'REJECTED',
                rejectionReason: 'Requested quantity exceeds available stock.',
                reviewedBy: 'N1',
                reviewedAt: new Date()
            };

            prismaMocks.findUnique.mockResolvedValue(pendingRequest);
            prismaMocks.update.mockResolvedValue(rejectedRequest);

            const result = await rejectFoodRequest(
                'req-123',
                'Requested quantity exceeds available stock.',
                'N1'
            );

            expect(prismaMocks.update).toHaveBeenCalledWith({
                where: { id: 'req-123' },
                data: {
                    status: 'REJECTED',
                    rejectionReason: 'Requested quantity exceeds available stock.',
                    reviewedBy: 'N1',
                    reviewedAt: expect.any(Date)
                }
            });
            expect(result.status).toBe('REJECTED');
            expect(result.rejectionReason).toBe('Requested quantity exceeds available stock.');
            expect(result.reviewedBy).toBe('N1');
        });

        it('throws an error when rejection reason is missing or empty', async () => {
            await expect(rejectFoodRequest('req-123', '', 'N1')).rejects.toThrow('Rejection reason is required');
        });

        it('throws an error when attempting to reject an already processed request', async () => {
            const alreadyApproved = {
                id: 'req-123',
                customRequestId: 'RQ1',
                foodItem: 'Hot Meals',
                status: 'APPROVED'
            };

            prismaMocks.findUnique.mockResolvedValue(alreadyApproved);

            await expect(rejectFoodRequest('req-123', 'Stock unavailable', 'N1')).rejects.toThrow(
                "Cannot reject request with status 'APPROVED'. Only pending requests can be rejected."
            );
        });
    });

    describe('createFoodRequest', () => {
        it('creates a new recipient request with default PENDING status', async () => {
            prismaMocks.findFirst.mockResolvedValue(null);
            prismaMocks.create.mockResolvedValue({
                id: 'req-1',
                customRequestId: 'RQ1',
                recipientId: 'R1',
                recipientEmail: 'recipient@example.com',
                foodItem: 'Fresh Vegetables',
                quantityRequested: '5 kg',
                status: 'PENDING'
            });

            const result = await createFoodRequest(
                {
                    foodItem: 'Fresh Vegetables',
                    quantityRequested: '5 kg'
                },
                {
                    customUserId: 'R1',
                    email: 'recipient@example.com'
                }
            );

            expect(prismaMocks.create).toHaveBeenCalledWith({
                data: expect.objectContaining({
                    customRequestId: 'RQ1',
                    recipientId: 'R1',
                    recipientEmail: 'recipient@example.com',
                    foodItem: 'Fresh Vegetables',
                    quantityRequested: '5 kg',
                    status: 'PENDING'
                })
            });
            expect(result.status).toBe('PENDING');
        });
    });
});
