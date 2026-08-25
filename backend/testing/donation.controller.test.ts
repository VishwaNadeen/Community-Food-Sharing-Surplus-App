import { beforeEach, describe, expect, it, vi } from 'vitest';

const donationServiceMocks = vi.hoisted(() => ({
    createDonation: vi.fn(),
    getDonationsByDonor: vi.fn(),
    updateDonation: vi.fn(),
    cancelDonation: vi.fn(),
}));

const validatorMocks = vi.hoisted(() => ({
    validateDonationInput: vi.fn(),
    validateDonationUpdateInput: vi.fn(),
}));

const cloudinaryMocks = vi.hoisted(() => ({
    uploadImageToCloudinary: vi.fn(),
}));

vi.mock('../src/services/donation.service', () => ({
    createDonation: donationServiceMocks.createDonation,
    getDonationsByDonor: donationServiceMocks.getDonationsByDonor,
    updateDonation: donationServiceMocks.updateDonation,
    cancelDonation: donationServiceMocks.cancelDonation,
}));

vi.mock('../src/validators/donation.validator', () => ({
    validateDonationInput: validatorMocks.validateDonationInput,
    validateDonationUpdateInput: validatorMocks.validateDonationUpdateInput,
}));

vi.mock('../src/services/cloudinary.service', () => ({
    uploadImageToCloudinary: cloudinaryMocks.uploadImageToCloudinary,
}));

import {
    create,
    getMyDonations,
    update,
    cancel,
} from '../src/controllers/donation.controller';

describe('donation controller', () => {
    beforeEach(() => {
        vi.clearAllMocks();

        validatorMocks.validateDonationInput.mockReturnValue([]);
        validatorMocks.validateDonationUpdateInput.mockReturnValue([]);
    });

    const createMockResponse = (roleCode = 'D') => {
        const res: any = {
            locals: {
                currentUser: {
                    user: {
                        customUserId: 'D1',
                        email: 'donor@example.com',
                        roleCode,
                    },
                },
            },
            status: vi.fn().mockReturnThis(),
            json: vi.fn().mockReturnThis(),
        };

        return res;
    };

    // =========================================================
    // CREATE DONATION
    // =========================================================

    describe('create', () => {
        it('creates a donation successfully', async () => {
            const donation = {
                id: 'donation-1',
                donorId: 'donor-1',
                category: 'Rice',
                quantity: 10,
                quantityUnit: 'KG',
                description: 'Fresh rice',
                status: 'AVAILABLE',
            };

            const req: any = {
                body: {
                    category: 'Rice',
                    quantity: 10,
                    quantityUnit: 'kg',
                    description: 'Fresh rice',
                    expiryDate: '2026-08-30',
                    pickupLocation: 'Colombo',
                    pickupDateTime: '2026-08-27T10:00:00',
                },
                file: undefined,
            };

            const res = createMockResponse('D');

            donationServiceMocks.createDonation.mockResolvedValue(donation);

            await create(req, res);

            expect(validatorMocks.validateDonationInput)
                .toHaveBeenCalledWith(req.body);

            expect(donationServiceMocks.createDonation)
                .toHaveBeenCalledWith(
                    'D1',
                    req.body,
                    undefined
                );

            expect(res.status).toHaveBeenCalledWith(201);

            expect(res.json).toHaveBeenCalledWith({
                message: 'Food donation created successfully',
                donation,
            });
        });

        it('returns 403 when a non-donor tries to create a donation', async () => {
            const req: any = {
                body: {},
                file: undefined,
            };

            const res = createMockResponse('R');

            await create(req, res);

            expect(res.status).toHaveBeenCalledWith(403);

            expect(res.json).toHaveBeenCalledWith({
                error: 'Only donors can create food donations',
            });

            expect(donationServiceMocks.createDonation)
                .not.toHaveBeenCalled();
        });

        it('returns 400 when donation validation fails', async () => {
            const validationErrors = [
                'Category is required.',
                'Quantity must be greater than 0.',
            ];

            validatorMocks.validateDonationInput
                .mockReturnValue(validationErrors);

            const req: any = {
                body: {
                    category: '',
                    quantity: -1,
                },
                file: undefined,
            };

            const res = createMockResponse('D');

            await create(req, res);

            expect(res.status).toHaveBeenCalledWith(400);

            expect(res.json).toHaveBeenCalledWith({
                errors: validationErrors,
            });

            expect(donationServiceMocks.createDonation)
                .not.toHaveBeenCalled();
        });

        it('uploads image and creates donation when file is provided', async () => {
            const donation = {
                id: 'donation-1',
                category: 'Rice',
                quantity: 10,
            };

            const imageUrl = 'https://cloudinary.com/image.jpg';

            const file = {
                buffer: Buffer.from('test-image'),
            };

            const req: any = {
                body: {
                    category: 'Rice',
                    quantity: 10,
                    quantityUnit: 'kg',
                },
                file,
            };

            const res = createMockResponse('D');

            cloudinaryMocks.uploadImageToCloudinary
                .mockResolvedValue(imageUrl);

            donationServiceMocks.createDonation
                .mockResolvedValue(donation);

            await create(req, res);

            expect(cloudinaryMocks.uploadImageToCloudinary)
                .toHaveBeenCalledWith(file.buffer);

            expect(donationServiceMocks.createDonation)
                .toHaveBeenCalledWith(
                    'D1',
                    req.body,
                    imageUrl
                );

            expect(res.status).toHaveBeenCalledWith(201);
        });

        it('returns 500 when createDonation throws an error', async () => {
            const req: any = {
                body: {
                    category: 'Rice',
                    quantity: 10,
                },
                file: undefined,
            };

            const res = createMockResponse('D');

            donationServiceMocks.createDonation
                .mockRejectedValue(new Error('Database error'));

            await create(req, res);

            expect(res.status).toHaveBeenCalledWith(500);

            expect(res.json).toHaveBeenCalledWith({
                error: 'Database error',
            });
        });
    });

    // =========================================================
    // GET MY DONATIONS
    // =========================================================

    describe('getMyDonations', () => {
        it('returns donations belonging to the current donor', async () => {
            const donations = [
                {
                    id: 'donation-1',
                    category: 'Rice',
                    quantity: 10,
                    status: 'AVAILABLE',
                },
                {
                    id: 'donation-2',
                    category: 'Bread',
                    quantity: 20,
                    status: 'AVAILABLE',
                },
            ];

            const req: any = {};
            const res = createMockResponse('D');

            donationServiceMocks.getDonationsByDonor
                .mockResolvedValue(donations);

            await getMyDonations(req, res);

            expect(donationServiceMocks.getDonationsByDonor)
                .toHaveBeenCalledWith('D1');

            expect(res.status).toHaveBeenCalledWith(200);

            expect(res.json).toHaveBeenCalledWith({
                donations,
            });
        });

        it('returns 403 when a non-donor tries to view donations', async () => {
            const req: any = {};
            const res = createMockResponse('R');

            await getMyDonations(req, res);

            expect(res.status).toHaveBeenCalledWith(403);

            expect(res.json).toHaveBeenCalledWith({
                error: 'Only donors can view their donations',
            });

            expect(donationServiceMocks.getDonationsByDonor)
                .not.toHaveBeenCalled();
        });

        it('returns 500 when getDonationsByDonor throws an error', async () => {
            const req: any = {};
            const res = createMockResponse('D');

            donationServiceMocks.getDonationsByDonor
                .mockRejectedValue(new Error('Database error'));

            await getMyDonations(req, res);

            expect(res.status).toHaveBeenCalledWith(500);

            expect(res.json).toHaveBeenCalledWith({
                error: 'Database error',
            });
        });
    });

    // =========================================================
    // UPDATE DONATION
    // =========================================================

    describe('update', () => {
        it('updates a donation successfully', async () => {
            const updatedDonation = {
                id: 'donation-1',
                donorId: 'donor-1',
                category: 'Vegetables',
                quantity: 15,
                quantityUnit: 'KG',
                description: 'Fresh vegetables',
                status: 'AVAILABLE',
            };

            const req: any = {
                params: {
                    id: 'donation-1',
                },
                body: {
                    category: 'Vegetables',
                    quantity: 15,
                    quantityUnit: 'kg',
                    description: 'Fresh vegetables',
                },
                file: undefined,
            };

            const res = createMockResponse('D');

            donationServiceMocks.updateDonation
                .mockResolvedValue(updatedDonation);

            await update(req, res);

            expect(validatorMocks.validateDonationUpdateInput)
                .toHaveBeenCalledWith(req.body);

            expect(donationServiceMocks.updateDonation)
                .toHaveBeenCalledWith(
                    'donation-1',
                    'D1',
                    req.body,
                    undefined
                );

            expect(res.status).toHaveBeenCalledWith(200);

            expect(res.json).toHaveBeenCalledWith({
                message: 'Food donation updated successfully',
                donation: updatedDonation,
            });
        });

        it('returns 403 when a non-donor tries to update a donation', async () => {
            const req: any = {
                params: {
                    id: 'donation-1',
                },
                body: {
                    category: 'Rice',
                },
                file: undefined,
            };

            const res = createMockResponse('R');

            await update(req, res);

            expect(res.status).toHaveBeenCalledWith(403);

            expect(res.json).toHaveBeenCalledWith({
                error: 'Only donors can edit food donations',
            });

            expect(donationServiceMocks.updateDonation)
                .not.toHaveBeenCalled();
        });

        it('returns 400 when update validation fails', async () => {
            const validationErrors = [
                'Quantity must be greater than 0.',
            ];

            validatorMocks.validateDonationUpdateInput
                .mockReturnValue(validationErrors);

            const req: any = {
                params: {
                    id: 'donation-1',
                },
                body: {
                    quantity: -5,
                },
                file: undefined,
            };

            const res = createMockResponse('D');

            await update(req, res);

            expect(res.status).toHaveBeenCalledWith(400);

            expect(res.json).toHaveBeenCalledWith({
                errors: validationErrors,
            });

            expect(donationServiceMocks.updateDonation)
                .not.toHaveBeenCalled();
        });

        it('uploads image when updating with a file', async () => {
            const updatedDonation = {
                id: 'donation-1',
                category: 'Rice',
                quantity: 10,
            };

            const imageUrl = 'https://cloudinary.com/new-image.jpg';

            const file = {
                buffer: Buffer.from('new-image'),
            };

            const req: any = {
                params: {
                    id: 'donation-1',
                },
                body: {
                    category: 'Rice',
                    quantity: 10,
                },
                file,
            };

            const res = createMockResponse('D');

            cloudinaryMocks.uploadImageToCloudinary
                .mockResolvedValue(imageUrl);

            donationServiceMocks.updateDonation
                .mockResolvedValue(updatedDonation);

            await update(req, res);

            expect(cloudinaryMocks.uploadImageToCloudinary)
                .toHaveBeenCalledWith(file.buffer);

            expect(donationServiceMocks.updateDonation)
                .toHaveBeenCalledWith(
                    'donation-1',
                    'D1',
                    req.body,
                    imageUrl
                );

            expect(res.status).toHaveBeenCalledWith(200);
        });

        it('returns 404 when donation does not exist', async () => {
            const req: any = {
                params: {
                    id: 'donation-1',
                },
                body: {
                    category: 'Rice',
                },
                file: undefined,
            };

            const res = createMockResponse('D');

            donationServiceMocks.updateDonation
                .mockRejectedValue(new Error('Donation not found'));

            await update(req, res);

            expect(res.status).toHaveBeenCalledWith(404);

            expect(res.json).toHaveBeenCalledWith({
                error: 'Donation not found',
            });
        });

        it('returns 403 when donor does not own the donation', async () => {
            const req: any = {
                params: {
                    id: 'donation-1',
                },
                body: {
                    category: 'Rice',
                },
                file: undefined,
            };

            const res = createMockResponse('D');

            donationServiceMocks.updateDonation
                .mockRejectedValue(
                    new Error(
                        'You are not allowed to edit this donation'
                    )
                );

            await update(req, res);

            expect(res.status).toHaveBeenCalledWith(403);

            expect(res.json).toHaveBeenCalledWith({
                error: 'You are not allowed to edit this donation',
            });
        });

        it('returns 403 when donation is not available', async () => {
            const req: any = {
                params: {
                    id: 'donation-1',
                },
                body: {
                    category: 'Rice',
                },
                file: undefined,
            };

            const res = createMockResponse('D');

            donationServiceMocks.updateDonation
                .mockRejectedValue(
                    new Error(
                        'Only available donations can be edited'
                    )
                );

            await update(req, res);

            expect(res.status).toHaveBeenCalledWith(403);

            expect(res.json).toHaveBeenCalledWith({
                error: 'Only available donations can be edited',
            });
        });

        it('returns 500 when updateDonation throws another error', async () => {
            const req: any = {
                params: {
                    id: 'donation-1',
                },
                body: {
                    category: 'Rice',
                },
                file: undefined,
            };

            const res = createMockResponse('D');

            donationServiceMocks.updateDonation
                .mockRejectedValue(new Error('Database error'));

            await update(req, res);

            expect(res.status).toHaveBeenCalledWith(500);

            expect(res.json).toHaveBeenCalledWith({
                error: 'Database error',
            });
        });
    });

    // =========================================================
    // CANCEL DONATION
    // =========================================================

    describe('cancel', () => {
        it('cancels a donation successfully', async () => {
            const cancelledDonation = {
                id: 'donation-1',
                donorId: 'donor-1',
                status: 'CANCELLED',
            };

            const req: any = {
                params: {
                    id: 'donation-1',
                },
            };

            const res = createMockResponse('D');

            donationServiceMocks.cancelDonation
                .mockResolvedValue(cancelledDonation);

            await cancel(req, res);

            expect(donationServiceMocks.cancelDonation)
                .toHaveBeenCalledWith(
                    'donation-1',
                    'D1'
                );

            expect(res.status).toHaveBeenCalledWith(200);

            expect(res.json).toHaveBeenCalledWith({
                message: 'Food donation cancelled successfully',
                donation: cancelledDonation,
            });
        });

        it('returns 403 when a non-donor tries to cancel a donation', async () => {
            const req: any = {
                params: {
                    id: 'donation-1',
                },
            };

            const res = createMockResponse('R');

            await cancel(req, res);

            expect(res.status).toHaveBeenCalledWith(403);

            expect(res.json).toHaveBeenCalledWith({
                error: 'Only donors can cancel food donations',
            });

            expect(donationServiceMocks.cancelDonation)
                .not.toHaveBeenCalled();
        });

        it('returns 404 when donation does not exist', async () => {
            const req: any = {
                params: {
                    id: 'donation-1',
                },
            };

            const res = createMockResponse('D');

            donationServiceMocks.cancelDonation
                .mockRejectedValue(
                    new Error('Donation not found')
                );

            await cancel(req, res);

            expect(res.status).toHaveBeenCalledWith(404);

            expect(res.json).toHaveBeenCalledWith({
                error: 'Donation not found',
            });
        });

        it('returns 403 when donor does not own the donation', async () => {
            const req: any = {
                params: {
                    id: 'donation-1',
                },
            };

            const res = createMockResponse('D');

            donationServiceMocks.cancelDonation
                .mockRejectedValue(
                    new Error(
                        'You are not allowed to cancel this donation'
                    )
                );

            await cancel(req, res);

            expect(res.status).toHaveBeenCalledWith(403);

            expect(res.json).toHaveBeenCalledWith({
                error: 'You are not allowed to cancel this donation',
            });
        });

        it('returns 403 when donation is not available', async () => {
            const req: any = {
                params: {
                    id: 'donation-1',
                },
            };

            const res = createMockResponse('D');

            donationServiceMocks.cancelDonation
                .mockRejectedValue(
                    new Error(
                        'Only available donations can be cancelled'
                    )
                );

            await cancel(req, res);

            expect(res.status).toHaveBeenCalledWith(403);

            expect(res.json).toHaveBeenCalledWith({
                error: 'Only available donations can be cancelled',
            });
        });

        it('returns 500 when cancelDonation throws another error', async () => {
            const req: any = {
                params: {
                    id: 'donation-1',
                },
            };

            const res = createMockResponse('D');

            donationServiceMocks.cancelDonation
                .mockRejectedValue(
                    new Error('Database error')
                );

            await cancel(req, res);

            expect(res.status).toHaveBeenCalledWith(500);

            expect(res.json).toHaveBeenCalledWith({
                error: 'Database error',
            });
        });
    });
});