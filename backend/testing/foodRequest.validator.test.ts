import { describe, expect, it } from 'vitest';
import {
    validateCreateFoodRequestInput,
    validateRejectFoodRequestInput
} from '../src/validators/foodRequest.validator';

describe('food request validators', () => {
    describe('validateRejectFoodRequestInput', () => {
        it('accepts a valid rejection payload with reason', () => {
            const result = validateRejectFoodRequestInput({
                rejectionReason: 'Recipient exceeds weekly allocation limit.'
            });
            expect(result).toEqual([]);
        });

        it('returns an error when rejectionReason is missing', () => {
            const result = validateRejectFoodRequestInput({});
            expect(result).toContain('Rejection reason is required.');
        });

        it('returns an error when rejectionReason is empty or only whitespace', () => {
            const result = validateRejectFoodRequestInput({
                rejectionReason: '    '
            });
            expect(result).toContain('Rejection reason is required.');
        });

        it('returns an error when rejectionReason is too short', () => {
            const result = validateRejectFoodRequestInput({
                rejectionReason: 'No'
            });
            expect(result).toContain('Rejection reason must be at least 3 characters long.');
        });
    });

    describe('validateCreateFoodRequestInput', () => {
        it('accepts a valid create food request payload', () => {
            const result = validateCreateFoodRequestInput({
                foodItem: 'Cooked Meals',
                quantityRequested: '4 packs',
                recipientName: 'Alice'
            });
            expect(result).toEqual([]);
        });

        it('returns an error when foodItem is missing', () => {
            const result = validateCreateFoodRequestInput({
                quantityRequested: '2 packs'
            });
            expect(result).toContain('Requested food item is required.');
        });

        it('returns an error when quantityRequested is missing', () => {
            const result = validateCreateFoodRequestInput({
                foodItem: 'Bread'
            });
            expect(result).toContain('Quantity requested is required.');
        });
    });
});
