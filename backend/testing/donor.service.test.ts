
import { beforeEach, describe, expect, it, vi } from 'vitest';

const prismaMocks = vi.hoisted(() => ({
    userFindUnique: vi.fn(),
    donorFindUnique: vi.fn(),
    donorCreate: vi.fn(),
    donorUpdate: vi.fn(),
    foodDonationUpdateMany: vi.fn(),
}));

vi.mock('@prisma/client', () => ({
    PrismaClient: vi.fn(() => ({
        user: {
            findUnique: prismaMocks.userFindUnique,
        },
        donor: {
            findUnique: prismaMocks.donorFindUnique,
            create: prismaMocks.donorCreate,
            update: prismaMocks.donorUpdate,
        },
        foodDonation: {
            updateMany: prismaMocks.foodDonationUpdateMany,
        },
    })),
}));

import {
    createDonorProfile,
    getDonorProfile,
    updateDonorProfile,
    getDonorProfileStatus,
} from '../src/services/donor.service';

import type { DonorProfileInput } from '../src/services/donor.service';

const customUserId = 'USER-D-001';

const validProfile: DonorProfileInput = {
    firstName: ' Nimesha ',
    lastName: ' Perera ',
    phoneNumber: ' 0771234567 ',
    donorType: 'INDIVIDUAL',
    addressLine1: ' 25 Main Street ',
    addressLine2: ' ',
    province: ' Western ',
    district: ' Colombo ',
    city: ' Colombo ',
    latitude: 6.9271,
    longitude: 79.8612,
    notes: ' Test donor ',
};

const donorUser = {
    id: 'user-id-001',
    customUserId,
    roleCode: 'D',
};

const nonDonorUser = {
    customUserId,
    roleCode: 'R',
};

const existingDonor = {
    id: 'donor-id-001',
    customUserId,
    firstName: 'Nimesha',
    lastName: 'Perera',
    phoneNumber: '0771234567',
    donorType: 'INDIVIDUAL',
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

describe('Donor Service', () => {
    beforeEach(() => {
        vi.clearAllMocks();
    });

    // --------------------------------------------------------
    // CREATE DONOR PROFILE
    // --------------------------------------------------------

    describe('createDonorProfile', () => {
        it('should create a valid individual donor profile', async () => {
            prismaMocks.userFindUnique.mockResolvedValue(donorUser);
            prismaMocks.donorFindUnique.mockResolvedValue(null);
            prismaMocks.donorCreate.mockResolvedValue(existingDonor);

            const result = await createDonorProfile(
                customUserId,
                validProfile,
            );

            expect(result).toEqual(existingDonor);

            expect(prismaMocks.donorCreate).toHaveBeenCalledWith({
                data: {
                    customUserId,
                    firstName: 'Nimesha',
                    lastName: 'Perera',
                    phoneNumber: '0771234567',
                    donorType: 'INDIVIDUAL',
                    organizationName: null,
                    addressLine1: '25 Main Street',
                    addressLine2: null,
                    province: 'Western',
                    district: 'Colombo',
                    city: 'Colombo',
                    latitude: 6.9271,
                    longitude: 79.8612,
                    notes: 'Test donor',
                },
            });
        });

        it('should copy the profile coordinates to existing donations', async () => {
            prismaMocks.userFindUnique.mockResolvedValue(donorUser);
            prismaMocks.donorFindUnique.mockResolvedValue(null);
            prismaMocks.donorCreate.mockResolvedValue(existingDonor);

            await createDonorProfile(customUserId, validProfile);

            expect(prismaMocks.foodDonationUpdateMany).toHaveBeenCalledWith({
                where: { donorId: 'user-id-001' },
                data: { latitude: 6.9271, longitude: 79.8612 },
            });
        });

        it('should throw an error when the user does not exist', async () => {
            prismaMocks.userFindUnique.mockResolvedValue(null);

            await expect(
                createDonorProfile(customUserId, validProfile),
            ).rejects.toThrow('User not found');

            expect(prismaMocks.donorCreate).not.toHaveBeenCalled();
        });

        it('should reject users who are not donors', async () => {
            prismaMocks.userFindUnique.mockResolvedValue(nonDonorUser);

            await expect(
                createDonorProfile(customUserId, validProfile),
            ).rejects.toThrow(
                'Only donor users can create a donor profile',
            );

            expect(prismaMocks.donorCreate).not.toHaveBeenCalled();
        });

        it('should reject duplicate donor profiles', async () => {
            prismaMocks.userFindUnique.mockResolvedValue(donorUser);
            prismaMocks.donorFindUnique.mockResolvedValue(existingDonor);

            await expect(
                createDonorProfile(customUserId, validProfile),
            ).rejects.toThrow('Donor profile already exists');

            expect(prismaMocks.donorCreate).not.toHaveBeenCalled();
        });

        it('should reject a missing required first name', async () => {
            prismaMocks.userFindUnique.mockResolvedValue(donorUser);
            prismaMocks.donorFindUnique.mockResolvedValue(null);

            const invalidProfile = {
                ...validProfile,
                firstName: '   ',
            };

            await expect(
                createDonorProfile(customUserId, invalidProfile),
            ).rejects.toThrow('firstName is required');

            expect(prismaMocks.donorCreate).not.toHaveBeenCalled();
        });

        it('should require an organization name for organization donors', async () => {
            prismaMocks.userFindUnique.mockResolvedValue(donorUser);
            prismaMocks.donorFindUnique.mockResolvedValue(null);

            const organizationProfile: DonorProfileInput = {
                ...validProfile,
                donorType: 'ORGANIZATION',
                organizationName: ' ',
            };

            await expect(
                createDonorProfile(customUserId, organizationProfile),
            ).rejects.toThrow(
                'Organization name is required for organization donors',
            );

            expect(prismaMocks.donorCreate).not.toHaveBeenCalled();
        });

        it('should reject an invalid donor type', async () => {
            prismaMocks.userFindUnique.mockResolvedValue(donorUser);
            prismaMocks.donorFindUnique.mockResolvedValue(null);

            const invalidProfile = {
                ...validProfile,
                donorType: 'COMPANY',
            } as unknown as DonorProfileInput;

            await expect(
                createDonorProfile(customUserId, invalidProfile),
            ).rejects.toThrow('Invalid donor type');
        });

        it('should reject latitude outside the valid range', async () => {
            prismaMocks.userFindUnique.mockResolvedValue(donorUser);
            prismaMocks.donorFindUnique.mockResolvedValue(null);

            const invalidProfile = {
                ...validProfile,
                latitude: 91,
            };

            await expect(
                createDonorProfile(customUserId, invalidProfile),
            ).rejects.toThrow('Latitude must be between -90 and 90');
        });

        it('should reject longitude outside the valid range', async () => {
            prismaMocks.userFindUnique.mockResolvedValue(donorUser);
            prismaMocks.donorFindUnique.mockResolvedValue(null);

            const invalidProfile = {
                ...validProfile,
                longitude: 181,
            };

            await expect(
                createDonorProfile(customUserId, invalidProfile),
            ).rejects.toThrow(
                'Longitude must be between -180 and 180',
            );
        });

        it('should reject coordinates provided separately', async () => {
            prismaMocks.userFindUnique.mockResolvedValue(donorUser);
            prismaMocks.donorFindUnique.mockResolvedValue(null);

            const invalidProfile = {
                ...validProfile,
                longitude: null,
            };

            await expect(
                createDonorProfile(customUserId, invalidProfile),
            ).rejects.toThrow(
                'Latitude and longitude must be provided together',
            );
        });

        it('should allow an organization with a valid organization name', async () => {
            prismaMocks.userFindUnique.mockResolvedValue(donorUser);
            prismaMocks.donorFindUnique.mockResolvedValue(null);
            prismaMocks.donorCreate.mockResolvedValue({
                ...existingDonor,
                donorType: 'ORGANIZATION',
                organizationName: 'Community Food Bank',
            });

            const organizationProfile: DonorProfileInput = {
                ...validProfile,
                donorType: 'ORGANIZATION',
                organizationName: ' Community Food Bank ',
            };

            const result = await createDonorProfile(
                customUserId,
                organizationProfile,
            );

            expect(result.organizationName).toBe('Community Food Bank');

            expect(prismaMocks.donorCreate).toHaveBeenCalledWith(
                expect.objectContaining({
                    data: expect.objectContaining({
                        donorType: 'ORGANIZATION',
                        organizationName: 'Community Food Bank',
                    }),
                }),
            );
        });
    });

    // --------------------------------------------------------
    // GET DONOR PROFILE
    // --------------------------------------------------------

    describe('getDonorProfile', () => {
        it('should return an existing donor profile', async () => {
            prismaMocks.donorFindUnique.mockResolvedValue(existingDonor);

            const result = await getDonorProfile(customUserId);

            expect(result).toEqual(existingDonor);
            expect(prismaMocks.donorFindUnique).toHaveBeenCalledWith({
                where: { customUserId },
            });
        });

        it('should return null when the donor profile does not exist', async () => {
            prismaMocks.donorFindUnique.mockResolvedValue(null);

            const result = await getDonorProfile(customUserId);

            expect(result).toBeNull();
        });
    });

    // --------------------------------------------------------
    // UPDATE DONOR PROFILE
    // --------------------------------------------------------

    describe('updateDonorProfile', () => {
        it('should update an existing donor profile', async () => {
            prismaMocks.donorFindUnique.mockResolvedValue(existingDonor);
            prismaMocks.donorUpdate.mockResolvedValue({
                ...existingDonor,
                firstName: 'Updated Name',
            });

            const result = await updateDonorProfile(customUserId, {
                firstName: ' Updated Name ',
            });

            expect(result.firstName).toBe('Updated Name');

            expect(prismaMocks.donorUpdate).toHaveBeenCalledWith({
                where: { customUserId },
                data: expect.objectContaining({
                    firstName: 'Updated Name',
                    organizationName: null,
                }),
            });
        });

        it('should sync the new map pin to all donations of the donor', async () => {
            prismaMocks.donorFindUnique.mockResolvedValue(existingDonor);
            prismaMocks.donorUpdate.mockResolvedValue({
                ...existingDonor,
                latitude: 7.2950,
                longitude: 80.6323,
            });
            prismaMocks.userFindUnique.mockResolvedValue(donorUser);

            await updateDonorProfile(customUserId, {
                latitude: 7.2950,
                longitude: 80.6323,
            });

            expect(prismaMocks.foodDonationUpdateMany).toHaveBeenCalledWith({
                where: { donorId: 'user-id-001' },
                data: { latitude: 7.2950, longitude: 80.6323 },
            });
        });

        it('should clear donation coordinates when the pin is removed', async () => {
            prismaMocks.donorFindUnique.mockResolvedValue(existingDonor);
            prismaMocks.donorUpdate.mockResolvedValue({
                ...existingDonor,
                latitude: null,
                longitude: null,
            });
            prismaMocks.userFindUnique.mockResolvedValue(donorUser);

            await updateDonorProfile(customUserId, {
                latitude: null,
                longitude: null,
            });

            expect(prismaMocks.foodDonationUpdateMany).toHaveBeenCalledWith({
                where: { donorId: 'user-id-001' },
                data: { latitude: null, longitude: null },
            });
        });

        it('should not sync donations when the update fails', async () => {
            prismaMocks.donorFindUnique.mockResolvedValue(existingDonor);

            await expect(
                updateDonorProfile(customUserId, { latitude: 200 }),
            ).rejects.toThrow();

            expect(prismaMocks.foodDonationUpdateMany).not.toHaveBeenCalled();
        });

        it('should throw an error when the donor profile does not exist', async () => {
            prismaMocks.donorFindUnique.mockResolvedValue(null);

            await expect(
                updateDonorProfile(customUserId, {
                    firstName: 'Updated Name',
                }),
            ).rejects.toThrow('Donor profile not found');

            expect(prismaMocks.donorUpdate).not.toHaveBeenCalled();
        });

        it('should reject an invalid latitude during an update', async () => {
            prismaMocks.donorFindUnique.mockResolvedValue(existingDonor);

            await expect(
                updateDonorProfile(customUserId, {
                    latitude: -91,
                }),
            ).rejects.toThrow('Latitude must be between -90 and 90');

            expect(prismaMocks.donorUpdate).not.toHaveBeenCalled();
        });

        it('should require an organization name when changing to organization', async () => {
            prismaMocks.donorFindUnique.mockResolvedValue(existingDonor);

            await expect(
                updateDonorProfile(customUserId, {
                    donorType: 'ORGANIZATION',
                }),
            ).rejects.toThrow(
                'Organization name is required for organization donors',
            );

            expect(prismaMocks.donorUpdate).not.toHaveBeenCalled();
        });
    });

    // --------------------------------------------------------
    // DONOR PROFILE STATUS
    // --------------------------------------------------------

    describe('getDonorProfileStatus', () => {
        it('should report an incomplete profile for a donor without a profile', async () => {
            prismaMocks.userFindUnique.mockResolvedValue(donorUser);
            prismaMocks.donorFindUnique.mockResolvedValue(null);

            const result = await getDonorProfileStatus(customUserId);

            expect(result).toEqual({
                isDonor: true,
                profileCompleted: false,
                profile: null,
            });
        });

        it('should report a completed profile for a donor with a profile', async () => {
            prismaMocks.userFindUnique.mockResolvedValue(donorUser);
            prismaMocks.donorFindUnique.mockResolvedValue(existingDonor);

            const result = await getDonorProfileStatus(customUserId);

            expect(result).toEqual({
                isDonor: true,
                profileCompleted: true,
                profile: existingDonor,
            });
        });

        it('should identify a non-donor user', async () => {
            prismaMocks.userFindUnique.mockResolvedValue(nonDonorUser);

            const result = await getDonorProfileStatus(customUserId);

            expect(result).toEqual({
                isDonor: false,
                profileCompleted: true,
                profile: null,
            });

            expect(prismaMocks.donorFindUnique).not.toHaveBeenCalled();
        });

        it('should throw an error when the user does not exist', async () => {
            prismaMocks.userFindUnique.mockResolvedValue(null);

            await expect(
                getDonorProfileStatus(customUserId),
            ).rejects.toThrow('User not found');
        });
    });
});
