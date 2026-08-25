import { describe, expect, it } from 'vitest';
import {
    validateDonationInput,
    validateDonationUpdateInput
} from '../src/validators/donation.validator';

describe('donation validators', () => {

    describe('validateDonationInput', () => {

        it('accepts a valid donation payload', () => {
            const result = validateDonationInput({
                category: 'Cooked Food',
                quantity: 20,
                quantityUnit: 'PACKETS',
                description: 'Fresh cooked meals',
                expiryDate: '2099-12-31T18:00:00.000Z',
                pickupLocation: 'Community Center',
                pickupDateTime: '2099-12-31T12:00:00.000Z'
            });

            expect(result).toEqual([]);
        });

        it('returns an error when required fields are missing', () => {
            const result = validateDonationInput({});

            expect(result).toContain('All donation fields are required.');
        });

        it('returns an error when quantity is invalid', () => {
            const result = validateDonationInput({
                category: 'Cooked Food',
                quantity: 0,
                quantityUnit: 'PACKETS',
                description: 'Fresh cooked meals',
                expiryDate: '2099-12-31T18:00:00.000Z',
                pickupLocation: 'Community Center',
                pickupDateTime: '2099-12-31T12:00:00.000Z'
            });

            expect(result).toContain('Quantity must be greater than 0.');
        });

        it('returns an error when quantity unit is invalid', () => {
            const result = validateDonationInput({
                category: 'Cooked Food',
                quantity: 20,
                quantityUnit: 'INVALID',
                description: 'Fresh cooked meals',
                expiryDate: '2099-12-31T18:00:00.000Z',
                pickupLocation: 'Community Center',
                pickupDateTime: '2099-12-31T12:00:00.000Z'
            });

            expect(result).toContain('Invalid quantity unit selected.');
        });

        it('returns an error when description is too short', () => {
            const result = validateDonationInput({
                category: 'Cooked Food',
                quantity: 20,
                quantityUnit: 'PACKETS',
                description: 'Food',
                expiryDate: '2099-12-31T18:00:00.000Z',
                pickupLocation: 'Community Center',
                pickupDateTime: '2099-12-31T12:00:00.000Z'
            });

            expect(result).toContain(
                'Description must be at least 5 characters long.'
            );
        });

        it('returns an error when expiry date is in the past', () => {
            const result = validateDonationInput({
                category: 'Cooked Food',
                quantity: 20,
                quantityUnit: 'PACKETS',
                description: 'Fresh cooked meals',
                expiryDate: '2020-01-01T18:00:00.000Z',
                pickupLocation: 'Community Center',
                pickupDateTime: '2099-12-31T12:00:00.000Z'
            });

            expect(result).toContain(
                'Expiry date must be in the future.'
            );
        });

        it('returns an error when pickup date is in the past', () => {
            const result = validateDonationInput({
                category: 'Cooked Food',
                quantity: 20,
                quantityUnit: 'PACKETS',
                description: 'Fresh cooked meals',
                expiryDate: '2099-12-31T18:00:00.000Z',
                pickupLocation: 'Community Center',
                pickupDateTime: '2020-01-01T12:00:00.000Z'
            });

            expect(result).toContain(
                'Pickup date and time must be in the future.'
            );
        });

    });

    describe('validateDonationUpdateInput', () => {

        it('accepts a valid update payload', () => {
            const result = validateDonationUpdateInput({
                quantity: 10,
                quantityUnit: 'KG',
                description: 'Updated food'
            });

            expect(result).toEqual([]);
        });

        it('returns an error when no fields are provided', () => {
            const result = validateDonationUpdateInput({});

            expect(result).toContain(
                'At least one donation field is required.'
            );
        });

        it('returns an error when update quantity is invalid', () => {
            const result = validateDonationUpdateInput({
                quantity: 0
            });

            expect(result).toContain(
                'Quantity must be greater than 0.'
            );
        });

        it('returns an error when update quantity unit is invalid', () => {
            const result = validateDonationUpdateInput({
                quantityUnit: 'INVALID'
            });

            expect(result).toContain(
                'Invalid quantity unit selected.'
            );
        });

        it('returns an error when update description is too short', () => {
            const result = validateDonationUpdateInput({
                description: 'abc'
            });

            expect(result).toContain(
                'Description must be at least 5 characters long.'
            );
        });

    });

});