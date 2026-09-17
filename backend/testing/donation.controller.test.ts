import { beforeEach, describe, expect, it, vi } from 'vitest';

const donationServiceMocks = vi.hoisted(() => ({
    createDonation: vi.fn(),
    getDonationsByDonor: vi.fn(),
    updateDonation: vi.fn(),
    cancelDonation: vi.fn()
}));

process.env.CLOUDINARY_CLOUD_NAME = 'test-cloud';
process.env.CLOUDINARY_API_KEY = 'test-key';
process.env.CLOUDINARY_API_SECRET = 'test-secret';

vi.mock('../src/services/cloudinary.service', () => ({
    uploadImageToCloudinary: vi.fn().mockResolvedValue('http://example.com/image.jpg')
}));

vi.mock('../src/services/donation.service', () => ({
    createDonation: donationServiceMocks.createDonation,
    getDonationsByDonor: donationServiceMocks.getDonationsByDonor,
    updateDonation: donationServiceMocks.updateDonation,
    cancelDonation: donationServiceMocks.cancelDonation
}));

import {
    cancel,
    create,
    getMyDonations,
    update
} from '../src/controllers/donation.controller';

describe('donation controller (donor operations)', () => {
    beforeEach(() => {
        vi.clearAllMocks();
    });

    const createMockResponse = (roleCode = 'D') => {
        const res: any = {
            locals: {
                currentUser: {
                    user: {
                        customUserId: 'D1',
                        email: 'donor@example.com',
                        roleCode
                    }
                }
            },
            status: vi.fn().mockReturnThis(),
            json: vi.fn().mockReturnThis()
        };
        return res;
    };

    describe('getMyDonations', () => {
        it('returns 200 and donor donations', async () => {
            const list = [{ id: 'don-1', category: 'Cooked Food' }];
            donationServiceMocks.getDonationsByDonor.mockResolvedValue(list);

            const req: any = {};
            const res = createMockResponse('D');

            await getMyDonations(req, res);

            expect(res.status).toHaveBeenCalledWith(200);
            expect(res.json).toHaveBeenCalledWith({ donations: list });
        });

        it('returns 403 if user is not a donor', async () => {
            const req: any = {};
            const res = createMockResponse('R');

            await getMyDonations(req, res);

            expect(res.status).toHaveBeenCalledWith(403);
            expect(res.json).toHaveBeenCalledWith({ error: 'Only donors can view their donations' });
        });
    });

    describe('cancel', () => {
        it('returns 200 on successful cancellation', async () => {
            const cancelled = { id: 'don-1', status: 'CANCELLED' };
            donationServiceMocks.cancelDonation.mockResolvedValue(cancelled);

            const req: any = { params: { id: 'don-1' } };
            const res = createMockResponse('D');

            await cancel(req, res);

            expect(res.status).toHaveBeenCalledWith(200);
            expect(res.json).toHaveBeenCalledWith({
                message: 'Food donation cancelled successfully',
                donation: cancelled
            });
        });
    });
});
