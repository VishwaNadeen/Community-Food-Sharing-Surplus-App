import { describe, expect, it } from 'vitest';
import {
    validateCreateDonationInput,
    validateRejectDonationInput
} from '../src/validators/donation.validator';

describe('donation validators', () => {
    describe('validateRejectDonationInput', () => {
        it('accepts a valid rejection payload with reason', () => {
            const result = validateRejectDonationInput({
                rejectionReason: 'Food items have passed the safe consumption date.'
            });
            expect(result).toEqual([]);
        });

        it('returns an error when rejectionReason is missing', () => {
            const result = validateRejectDonationInput({});
            expect(result).toContain('Rejection reason is required.');
        });

        it('returns an error when rejectionReason is empty or only whitespace', () => {
            const result = validateRejectDonationInput({
                rejectionReason: '   '
            });
            expect(result).toContain('Rejection reason is required.');
        });

        it('returns an error when rejectionReason is too short', () => {
            const result = validateRejectDonationInput({
                rejectionReason: 'No'
            });
            expect(result).toContain('Rejection reason must be at least 3 characters long.');
        });
    });

    describe('validateCreateDonationInput', () => {
        it('accepts a valid create donation payload', () => {
            const result = validateCreateDonationInput({
                title: 'Surplus Cooked Meals',
                quantity: '20 packs',
                foodType: 'Cooked'
            });
            expect(result).toEqual([]);
        });

        it('returns an error when title is missing', () => {
            const result = validateCreateDonationInput({
                quantity: '10 kg'
            });
            expect(result).toContain('Food title is required.');
        });

        it('returns an error when quantity is missing', () => {
            const result = validateCreateDonationInput({
                title: 'Fresh Bread'
            });
            expect(result).toContain('Quantity is required.');
        });
    });
});
