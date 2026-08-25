import { beforeEach, describe, expect, it, vi } from 'vitest';

const prismaMocks = vi.hoisted(() => ({
    userFindUnique: vi.fn(),
    foodDonationFindUnique: vi.fn(),
    foodDonationFindMany: vi.fn(),
    foodDonationCreate: vi.fn(),
    foodDonationUpdate: vi.fn()
}));

vi.mock('@prisma/client', () => ({
    DonationStatus: {
        AVAILABLE: 'AVAILABLE',
        CANCELLED: 'CANCELLED'
    },
    QuantityUnit: {
        KG: 'KG',
        G: 'G',
        L: 'L',
        ML: 'ML',
        PIECES: 'PIECES'
    },
    PrismaClient: class {
        user = {
            findUnique: prismaMocks.userFindUnique
        };

        foodDonation = {
            findUnique: prismaMocks.foodDonationFindUnique,
            findMany: prismaMocks.foodDonationFindMany,
            create: prismaMocks.foodDonationCreate,
            update: prismaMocks.foodDonationUpdate
        };
    }
}));

import {
    createDonation,
    getDonationsByDonor,
    updateDonation,
    cancelDonation
} from '../src/services/donation.service';

describe('donation service', () => {
    beforeEach(() => {
        vi.clearAllMocks();
    });

    describe('createDonation', () => {
        it('creates a donation for an existing donor', async () => {
            const donor = {
                id: 'donor-1',
                customUserId: 'D1'
            };

            const createdDonation = {
                id: 'donation-1',
                donorId: 'donor-1',
                category: 'Rice',
                quantity: 10,
                quantityUnit: 'KG',
                description: 'Fresh rice',
                expiryDate: new Date('2026-08-30'),
                imageUrl: null,
                pickupLocation: 'Colombo',
                pickupDateTime: new Date('2026-08-27T10:00:00'),
                status: 'AVAILABLE'
            };

            prismaMocks.userFindUnique.mockResolvedValue(donor);
            prismaMocks.foodDonationCreate.mockResolvedValue(createdDonation);

            const result = await createDonation(
                'D1',
                {
                    category: ' Rice ',
                    quantity: 10,
                    quantityUnit: 'kg',
                    description: ' Fresh rice ',
                    expiryDate: '2026-08-30',
                    pickupLocation: ' Colombo ',
                    pickupDateTime: '2026-08-27T10:00:00'
                },
                undefined
            );

            expect(prismaMocks.userFindUnique).toHaveBeenCalledWith({
                where: {
                    customUserId: 'D1'
                }
            });

            expect(prismaMocks.foodDonationCreate).toHaveBeenCalledWith({
                data: {
                    donorId: 'donor-1',
                    category: 'Rice',
                    quantity: 10,
                    quantityUnit: 'KG',
                    description: 'Fresh rice',
                    expiryDate: expect.any(Date),
                    imageUrl: null,
                    pickupLocation: 'Colombo',
                    pickupDateTime: expect.any(Date),
                    status: 'AVAILABLE'
                }
            });

            expect(result).toEqual(createdDonation);
        });

        it('throws error when donor does not exist', async () => {
            prismaMocks.userFindUnique.mockResolvedValue(null);

            await expect(
                createDonation(
                    'D999',
                    {
                        category: 'Rice',
                        quantity: 10,
                        quantityUnit: 'kg',
                        description: 'Fresh rice',
                        expiryDate: '2026-08-30',
                        pickupLocation: 'Colombo',
                        pickupDateTime: '2026-08-27T10:00:00'
                    }
                )
            ).rejects.toThrow('Donor not found');

            expect(prismaMocks.foodDonationCreate).not.toHaveBeenCalled();
        });
    });

    describe('getDonationsByDonor', () => {
        it('returns donations belonging to the donor', async () => {
            const donor = {
                id: 'donor-1',
                customUserId: 'D1'
            };

            const donations = [
                {
                    id: 'donation-1',
                    donorId: 'donor-1',
                    category: 'Rice',
                    quantity: 10,
                    quantityUnit: 'KG',
                    status: 'AVAILABLE'
                },
                {
                    id: 'donation-2',
                    donorId: 'donor-1',
                    category: 'Bread',
                    quantity: 20,
                    quantityUnit: 'PIECES',
                    status: 'AVAILABLE'
                }
            ];

            prismaMocks.userFindUnique.mockResolvedValue(donor);
            prismaMocks.foodDonationFindMany.mockResolvedValue(donations);

            const result = await getDonationsByDonor('D1');

            expect(prismaMocks.userFindUnique).toHaveBeenCalledWith({
                where: {
                    customUserId: 'D1'
                }
            });

            expect(prismaMocks.foodDonationFindMany).toHaveBeenCalledWith({
                where: {
                    donorId: 'donor-1'
                },
                orderBy: {
                    createdAt: 'desc'
                }
            });

            expect(result).toHaveLength(2);
            expect(result[0].id).toBe('donation-1');
        });

        it('throws error when donor does not exist', async () => {
            prismaMocks.userFindUnique.mockResolvedValue(null);

            await expect(
                getDonationsByDonor('D999')
            ).rejects.toThrow('Donor not found');

            expect(prismaMocks.foodDonationFindMany).not.toHaveBeenCalled();
        });
    });

    describe('updateDonation', () => {
        it('updates an available donation belonging to the donor', async () => {
            const donor = {
                id: 'donor-1',
                customUserId: 'D1'
            };

            const donation = {
                id: 'donation-1',
                donorId: 'donor-1',
                status: 'AVAILABLE'
            };

            const updatedDonation = {
                ...donation,
                category: 'Vegetables',
                quantity: 15,
                quantityUnit: 'KG',
                description: 'Fresh vegetables'
            };

            prismaMocks.userFindUnique.mockResolvedValue(donor);
            prismaMocks.foodDonationFindUnique.mockResolvedValue(donation);
            prismaMocks.foodDonationUpdate.mockResolvedValue(updatedDonation);

            const result = await updateDonation(
                'donation-1',
                'D1',
                {
                    category: ' Vegetables ',
                    quantity: 15,
                    quantityUnit: 'kg',
                    description: ' Fresh vegetables '
                }
            );

            expect(prismaMocks.foodDonationUpdate).toHaveBeenCalledWith({
                where: {
                    id: 'donation-1'
                },
                data: {
                    category: 'Vegetables',
                    quantity: 15,
                    quantityUnit: 'KG',
                    description: 'Fresh vegetables'
                }
            });

            expect(result).toEqual(updatedDonation);
        });

        it('throws error when donor does not exist', async () => {
            prismaMocks.userFindUnique.mockResolvedValue(null);

            await expect(
                updateDonation(
                    'donation-1',
                    'D999',
                    {
                        category: 'Rice'
                    }
                )
            ).rejects.toThrow('Donor not found');
        });

        it('throws error when donation does not exist', async () => {
            prismaMocks.userFindUnique.mockResolvedValue({
                id: 'donor-1',
                customUserId: 'D1'
            });

            prismaMocks.foodDonationFindUnique.mockResolvedValue(null);

            await expect(
                updateDonation(
                    'donation-1',
                    'D1',
                    {
                        category: 'Rice'
                    }
                )
            ).rejects.toThrow('Donation not found');
        });

        it('throws error when donor does not own the donation', async () => {
            prismaMocks.userFindUnique.mockResolvedValue({
                id: 'donor-1',
                customUserId: 'D1'
            });

            prismaMocks.foodDonationFindUnique.mockResolvedValue({
                id: 'donation-1',
                donorId: 'another-donor',
                status: 'AVAILABLE'
            });

            await expect(
                updateDonation(
                    'donation-1',
                    'D1',
                    {
                        category: 'Rice'
                    }
                )
            ).rejects.toThrow(
                'You are not allowed to edit this donation'
            );
        });

        it('throws error when donation is not available', async () => {
            prismaMocks.userFindUnique.mockResolvedValue({
                id: 'donor-1',
                customUserId: 'D1'
            });

            prismaMocks.foodDonationFindUnique.mockResolvedValue({
                id: 'donation-1',
                donorId: 'donor-1',
                status: 'CANCELLED'
            });

            await expect(
                updateDonation(
                    'donation-1',
                    'D1',
                    {
                        category: 'Rice'
                    }
                )
            ).rejects.toThrow(
                'Only available donations can be edited'
            );
        });
    });

    describe('cancelDonation', () => {
        it('cancels an available donation belonging to the donor', async () => {
            const donor = {
                id: 'donor-1',
                customUserId: 'D1'
            };

            const donation = {
                id: 'donation-1',
                donorId: 'donor-1',
                status: 'AVAILABLE'
            };

            const cancelledDonation = {
                ...donation,
                status: 'CANCELLED'
            };

            prismaMocks.userFindUnique.mockResolvedValue(donor);
            prismaMocks.foodDonationFindUnique.mockResolvedValue(donation);
            prismaMocks.foodDonationUpdate.mockResolvedValue(
                cancelledDonation
            );

            const result = await cancelDonation(
                'donation-1',
                'D1'
            );

            expect(prismaMocks.foodDonationUpdate).toHaveBeenCalledWith({
                where: {
                    id: 'donation-1'
                },
                data: {
                    status: 'CANCELLED'
                }
            });

            expect(result.status).toBe('CANCELLED');
        });

        it('throws error when donor does not exist', async () => {
            prismaMocks.userFindUnique.mockResolvedValue(null);

            await expect(
                cancelDonation('donation-1', 'D999')
            ).rejects.toThrow('Donor not found');
        });

        it('throws error when donation does not exist', async () => {
            prismaMocks.userFindUnique.mockResolvedValue({
                id: 'donor-1',
                customUserId: 'D1'
            });

            prismaMocks.foodDonationFindUnique.mockResolvedValue(null);

            await expect(
                cancelDonation('donation-1', 'D1')
            ).rejects.toThrow('Donation not found');
        });

        it('throws error when donor does not own the donation', async () => {
            prismaMocks.userFindUnique.mockResolvedValue({
                id: 'donor-1',
                customUserId: 'D1'
            });

            prismaMocks.foodDonationFindUnique.mockResolvedValue({
                id: 'donation-1',
                donorId: 'another-donor',
                status: 'AVAILABLE'
            });

            await expect(
                cancelDonation('donation-1', 'D1')
            ).rejects.toThrow(
                'You are not allowed to cancel this donation'
            );
        });

        it('throws error when donation is not available', async () => {
            prismaMocks.userFindUnique.mockResolvedValue({
                id: 'donor-1',
                customUserId: 'D1'
            });

            prismaMocks.foodDonationFindUnique.mockResolvedValue({
                id: 'donation-1',
                donorId: 'donor-1',
                status: 'CANCELLED'
            });

            await expect(
                cancelDonation('donation-1', 'D1')
            ).rejects.toThrow(
                'Only available donations can be cancelled'
            );
        });
    });
});