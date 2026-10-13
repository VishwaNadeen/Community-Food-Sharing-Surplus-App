
import { beforeEach, describe, expect, it, vi } from 'vitest';
import type { Request, Response } from 'express';
import type { AuthLocals } from '../src/middleware/auth.middleware';

vi.mock('../src/services/donor.service', () => ({
    createDonorProfile: vi.fn(),
    getDonorProfile: vi.fn(),
    updateDonorProfile: vi.fn(),
    getDonorProfileStatus: vi.fn(),
}));

import {
    createDonorProfile,
    getDonorProfile,
    updateDonorProfile,
    getDonorProfileStatus,
    type DonorProfileInput,
} from '../src/services/donor.service';

import {
    getDonorProfileHandler,
    createDonorProfileHandler,
    updateDonorProfileHandler,
    getDonorProfileStatusHandler,
} from '../src/controllers/donor.controller';

const customUserId = 'USER-D-001';

const profile = {
    id: 'donor-id-001',
    customUserId,
    firstName: 'Test',
    lastName: 'Donor',
    phoneNumber: '0771234567',
    donorType: 'INDIVIDUAL' as const,
    organizationName: null,
    addressLine1: '25 Main Street',
    addressLine2: null,
    province: 'Western',
    district: 'Colombo',
    city: 'Colombo',
    latitude: 6.9271,
    longitude: 79.8612,
    notes: null,
};

const profileInput: DonorProfileInput = {
    firstName: 'Test',
    lastName: 'Donor',
    phoneNumber: '0771234567',
    donorType: 'INDIVIDUAL',
    addressLine1: '25 Main Street',
    province: 'Western',
    district: 'Colombo',
    city: 'Colombo',
};

function createMocks(body: unknown = {}) {
    const responseData: {
        statusCode: number;
        body: unknown;
    } = {
        statusCode: 200,
        body: undefined,
    };

    const req = {
        body,
    } as Request;

    let res: Response<any, AuthLocals>;

    const responseMock = {
        locals: {
            currentUser: {
                user: {
                    customUserId,
                    roleCode: 'D',
                },
            },
        },
        status: vi.fn((statusCode: number) => {
            responseData.statusCode = statusCode;
            return responseMock;
        }),
        json: vi.fn((data: unknown) => {
            responseData.body = data;
            return responseMock;
        }),
    };

    res = responseMock as unknown as Response<any, AuthLocals>;

    return { req, res, responseData };
}

describe('Donor Controller', () => {
    beforeEach(() => {
        vi.clearAllMocks();
    });

    describe('getDonorProfileHandler', () => {
        it('returns the donor profile with status 200', async () => {
            vi.mocked(getDonorProfile).mockResolvedValue(profile as never);

            const { req, res, responseData } = createMocks();

            await getDonorProfileHandler(req, res);

            expect(getDonorProfile).toHaveBeenCalledWith(customUserId);
            expect(responseData.statusCode).toBe(200);
            expect(responseData.body).toEqual({
                profile,
                profileCompleted: true,
            });
        });

        it('returns an incomplete profile when none exists', async () => {
            vi.mocked(getDonorProfile).mockResolvedValue(null);

            const { req, res, responseData } = createMocks();

            await getDonorProfileHandler(req, res);

            expect(responseData.statusCode).toBe(200);
            expect(responseData.body).toEqual({
                profile: null,
                profileCompleted: false,
            });
        });

        it('returns 500 when profile retrieval fails', async () => {
            vi.mocked(getDonorProfile).mockRejectedValue(
                new Error('Database unavailable'),
            );

            const { req, res, responseData } = createMocks();

            await getDonorProfileHandler(req, res);

            expect(responseData.statusCode).toBe(500);
            expect(responseData.body).toEqual({
                error: 'Database unavailable',
            });
        });
    });

    describe('createDonorProfileHandler', () => {
        it('creates a profile and returns 201', async () => {
            vi.mocked(createDonorProfile).mockResolvedValue(profile as never);

            const { req, res, responseData } = createMocks(profileInput);

            await createDonorProfileHandler(
                req as Request & { body: DonorProfileInput },
                res,
            );

            expect(createDonorProfile).toHaveBeenCalledWith(
                customUserId,
                profileInput,
            );
            expect(responseData.statusCode).toBe(201);
            expect(responseData.body).toEqual({
                message: 'Donor profile created successfully',
                profile,
                profileCompleted: true,
            });
        });

        it('returns 404 when the user does not exist', async () => {
            vi.mocked(createDonorProfile).mockRejectedValue(
                new Error('User not found'),
            );

            const { req, res, responseData } = createMocks(profileInput);

            await createDonorProfileHandler(
                req as Request & { body: DonorProfileInput },
                res,
            );

            expect(responseData.statusCode).toBe(404);
            expect(responseData.body).toEqual({ error: 'User not found' });
        });

        it('returns 409 when the profile already exists', async () => {
            vi.mocked(createDonorProfile).mockRejectedValue(
                new Error('Donor profile already exists'),
            );

            const { req, res, responseData } = createMocks(profileInput);

            await createDonorProfileHandler(
                req as Request & { body: DonorProfileInput },
                res,
            );

            expect(responseData.statusCode).toBe(409);
            expect(responseData.body).toEqual({
                error: 'Donor profile already exists',
            });
        });

        it('returns 403 when the user is not a donor', async () => {
            vi.mocked(createDonorProfile).mockRejectedValue(
                new Error('Only donor users can create a donor profile'),
            );

            const { req, res, responseData } = createMocks(profileInput);

            await createDonorProfileHandler(
                req as Request & { body: DonorProfileInput },
                res,
            );

            expect(responseData.statusCode).toBe(403);
            expect(responseData.body).toEqual({
                error: 'Only donor users can create a donor profile',
            });
        });

        it('returns 400 when profile data is invalid', async () => {
            vi.mocked(createDonorProfile).mockRejectedValue(
                new Error('firstName is required'),
            );

            const { req, res, responseData } = createMocks({});

            await createDonorProfileHandler(
                req as Request & { body: DonorProfileInput },
                res,
            );

            expect(responseData.statusCode).toBe(400);
            expect(responseData.body).toEqual({
                error: 'firstName is required',
            });
        });
    });

    describe('updateDonorProfileHandler', () => {
        it('updates the profile and returns 200', async () => {
            const updatedProfile = {
                ...profile,
                firstName: 'Updated',
            };

            vi.mocked(updateDonorProfile).mockResolvedValue(
                updatedProfile as never,
            );

            const updateInput: DonorProfileInput = {
                firstName: 'Updated',
            };

            const { req, res, responseData } = createMocks(updateInput);

            await updateDonorProfileHandler(
                req as Request & { body: DonorProfileInput },
                res,
            );

            expect(updateDonorProfile).toHaveBeenCalledWith(
                customUserId,
                updateInput,
            );
            expect(responseData.statusCode).toBe(200);
            expect(responseData.body).toEqual({
                message: 'Donor profile updated successfully',
                profile: updatedProfile,
                profileCompleted: true,
            });
        });

        it('returns 404 when the profile does not exist', async () => {
            vi.mocked(updateDonorProfile).mockRejectedValue(
                new Error('Donor profile not found'),
            );

            const { req, res, responseData } = createMocks({
                firstName: 'Updated',
            });

            await updateDonorProfileHandler(
                req as Request & { body: DonorProfileInput },
                res,
            );

            expect(responseData.statusCode).toBe(404);
            expect(responseData.body).toEqual({
                error: 'Donor profile not found',
            });
        });

        it('returns 403 when the service rejects the user role', async () => {
            vi.mocked(updateDonorProfile).mockRejectedValue(
                new Error('Only donor users can update a donor profile'),
            );

            const { req, res, responseData } = createMocks({
                firstName: 'Updated',
            });

            await updateDonorProfileHandler(
                req as Request & { body: DonorProfileInput },
                res,
            );

            expect(responseData.statusCode).toBe(403);
            expect(responseData.body).toEqual({
                error: 'Only donor users can update a donor profile',
            });
        });

        it('returns 400 when update data is invalid', async () => {
            vi.mocked(updateDonorProfile).mockRejectedValue(
                new Error('Latitude must be between -90 and 90'),
            );

            const { req, res, responseData } = createMocks({
                latitude: 100,
            });

            await updateDonorProfileHandler(
                req as Request & { body: DonorProfileInput },
                res,
            );

            expect(responseData.statusCode).toBe(400);
            expect(responseData.body).toEqual({
                error: 'Latitude must be between -90 and 90',
            });
        });
    });

    describe('getDonorProfileStatusHandler', () => {
        it('returns donor profile status with 200', async () => {
            const status = {
                isDonor: true,
                profileCompleted: true,
                profile,
            };

            vi.mocked(getDonorProfileStatus).mockResolvedValue(status as never);

            const { req, res, responseData } = createMocks();

            await getDonorProfileStatusHandler(req, res);

            expect(getDonorProfileStatus).toHaveBeenCalledWith(customUserId);
            expect(responseData.statusCode).toBe(200);
            expect(responseData.body).toEqual(status);
        });

        it('returns 404 when the user does not exist', async () => {
            vi.mocked(getDonorProfileStatus).mockRejectedValue(
                new Error('User not found'),
            );

            const { req, res, responseData } = createMocks();

            await getDonorProfileStatusHandler(req, res);

            expect(responseData.statusCode).toBe(404);
            expect(responseData.body).toEqual({ error: 'User not found' });
        });

        it('returns 500 when status retrieval fails unexpectedly', async () => {
            vi.mocked(getDonorProfileStatus).mockRejectedValue(
                new Error('Database unavailable'),
            );

            const { req, res, responseData } = createMocks();

            await getDonorProfileStatusHandler(req, res);

            expect(responseData.statusCode).toBe(500);
            expect(responseData.body).toEqual({
                error: 'Database unavailable',
            });
        });
    });
});
