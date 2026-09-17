import { beforeEach, describe, expect, it, vi } from 'vitest';

const prismaMocks = vi.hoisted(() => ({
    findUnique: vi.fn(),
    findFirst: vi.fn(),
    findMany: vi.fn(),
    create: vi.fn(),
    update: vi.fn()
}));

vi.mock('@prisma/client', () => ({
    PrismaClient: vi.fn().mockImplementation(() => ({
        foodDonation: {
            findUnique: prismaMocks.findUnique,
            findFirst: prismaMocks.findFirst,
            findMany: prismaMocks.findMany,
            create: prismaMocks.create,
            update: prismaMocks.update
        }
    })),
    DonationStatus: {
        PENDING: 'PENDING',
        APPROVED: 'APPROVED',
        REJECTED: 'REJECTED',
        AVAILABLE: 'AVAILABLE',
        CANCELLED: 'CANCELLED',
        COLLECTED: 'COLLECTED',
        EXPIRED: 'EXPIRED'
    }
}));

import {
    approveDonation,
    getDonationById,
    getPendingDonations,
    rejectDonation
} from '../src/services/donation.service';

describe('donation service', () => {
    beforeEach(() => {
        vi.clearAllMocks();
    });

    describe('getPendingDonations', () => {
        it('returns all donations with status PENDING', async () => {
            const mockPendingDonations = [
                {
                    id: 'don-1',
                    category: 'Cooked Food',
                    quantity: 15,
                    status: 'PENDING',
                    donorId: 'user-1',
                    createdAt: new Date()
                },
                {
                    id: 'don-2',
                    category: 'Bakery',
                    quantity: 30,
                    status: 'PENDING',
                    donorId: 'user-2',
                    createdAt: new Date()
                }
            ];

            prismaMocks.findMany.mockResolvedValue(mockPendingDonations);

            const result = await getPendingDonations();

            expect(prismaMocks.findMany).toHaveBeenCalledWith({
                where: { status: 'PENDING' },
                orderBy: { createdAt: 'desc' }
            });
            expect(result).toHaveLength(2);
            expect(result[0].status).toBe('PENDING');
        });
    });

    describe('getDonationById', () => {
        it('returns donation when found by id', async () => {
            const mockDonation = {
                id: 'don-123',
                category: 'Vegetables',
                quantity: 10,
                status: 'PENDING',
                donorId: 'user-1'
            };

            prismaMocks.findUnique.mockResolvedValue(mockDonation);

            const result = await getDonationById('don-123');

            expect(prismaMocks.findUnique).toHaveBeenCalledWith({ where: { id: 'don-123' } });
            expect(result.id).toBe('don-123');
            expect(result.category).toBe('Vegetables');
        });

        it('throws error when donation does not exist', async () => {
            prismaMocks.findUnique.mockResolvedValue(null);

            await expect(getDonationById('non-existent-id')).rejects.toThrow('Donation not found');
        });
    });

    describe('approveDonation', () => {
        it('approves a pending donation and sets coordinator audit info', async () => {
            const pendingDonation = {
                id: 'don-123',
                category: 'Fruits',
                quantity: 5,
                status: 'PENDING',
                donorId: 'user-1',
                reviewedBy: null,
                reviewedAt: null
            };

            const approvedDonation = {
                ...pendingDonation,
                status: 'APPROVED',
                rejectionReason: null,
                reviewedBy: 'N1',
                reviewedAt: new Date()
            };

            prismaMocks.findUnique.mockResolvedValue(pendingDonation);
            prismaMocks.update.mockResolvedValue(approvedDonation);

            const result = await approveDonation('don-123', 'N1');

            expect(prismaMocks.update).toHaveBeenCalledWith({
                where: { id: 'don-123' },
                data: {
                    status: 'APPROVED',
                    rejectionReason: null,
                    reviewedBy: 'N1',
                    reviewedAt: expect.any(Date)
                }
            });
            expect(result.status).toBe('APPROVED');
            expect(result.reviewedBy).toBe('N1');
        });

        it('throws an error if donation is already approved', async () => {
            const alreadyApproved = {
                id: 'don-123',
                category: 'Fruits',
                quantity: 5,
                status: 'APPROVED',
                donorId: 'user-1'
            };

            prismaMocks.findUnique.mockResolvedValue(alreadyApproved);

            await expect(approveDonation('don-123', 'N1')).rejects.toThrow(
                "Cannot approve donation with status 'APPROVED'. Only pending donations can be approved."
            );
        });

        it('throws an error if donation is already rejected', async () => {
            const alreadyRejected = {
                id: 'don-123',
                category: 'Fruits',
                quantity: 5,
                status: 'REJECTED',
                rejectionReason: 'Expired',
                donorId: 'user-1'
            };

            prismaMocks.findUnique.mockResolvedValue(alreadyRejected);

            await expect(approveDonation('don-123', 'N1')).rejects.toThrow(
                "Cannot approve donation with status 'REJECTED'. Only pending donations can be approved."
            );
        });
    });

    describe('rejectDonation', () => {
        it('rejects a pending donation with rejection reason and audit info', async () => {
            const pendingDonation = {
                id: 'don-123',
                category: 'Cooked Food',
                quantity: 10,
                status: 'PENDING',
                donorId: 'user-1'
            };

            const rejectedDonation = {
                ...pendingDonation,
                status: 'REJECTED',
                rejectionReason: 'Packaging is damaged and not suitable for transport.',
                reviewedBy: 'N1',
                reviewedAt: new Date()
            };

            prismaMocks.findUnique.mockResolvedValue(pendingDonation);
            prismaMocks.update.mockResolvedValue(rejectedDonation);

            const result = await rejectDonation(
                'don-123',
                'Packaging is damaged and not suitable for transport.',
                'N1'
            );

            expect(prismaMocks.update).toHaveBeenCalledWith({
                where: { id: 'don-123' },
                data: {
                    status: 'REJECTED',
                    rejectionReason: 'Packaging is damaged and not suitable for transport.',
                    reviewedBy: 'N1',
                    reviewedAt: expect.any(Date)
                }
            });
            expect(result.status).toBe('REJECTED');
            expect(result.rejectionReason).toBe('Packaging is damaged and not suitable for transport.');
            expect(result.reviewedBy).toBe('N1');
        });

        it('throws error when rejection reason is missing or empty', async () => {
            await expect(rejectDonation('don-123', '', 'N1')).rejects.toThrow('Rejection reason is required');
        });

        it('throws error if attempting to reject an already processed donation', async () => {
            const alreadyApproved = {
                id: 'don-123',
                category: 'Milk',
                quantity: 4,
                status: 'APPROVED',
                donorId: 'user-1'
            };

            prismaMocks.findUnique.mockResolvedValue(alreadyApproved);

            await expect(rejectDonation('don-123', 'Expired', 'N1')).rejects.toThrow(
                "Cannot reject donation with status 'APPROVED'. Only pending donations can be rejected."
            );
        });
    });
});
