import { describe, expect, it } from 'vitest';
import { ngoService } from '../src/services/ngo.service';

describe('ngo service module exports', () => {
    it('exports all expected donation operations', () => {
        expect(ngoService.getPendingDonations).toBeDefined();
        expect(ngoService.getDonationById).toBeDefined();
        expect(ngoService.approveDonation).toBeDefined();
        expect(ngoService.rejectDonation).toBeDefined();
        expect(ngoService.getAllDonations).toBeDefined();
    });

    it('exports all expected food request operations', () => {
        expect(ngoService.getPendingFoodRequests).toBeDefined();
        expect(ngoService.getFoodRequestById).toBeDefined();
        expect(ngoService.approveFoodRequest).toBeDefined();
        expect(ngoService.rejectFoodRequest).toBeDefined();
        expect(ngoService.getAllFoodRequests).toBeDefined();
    });
});
