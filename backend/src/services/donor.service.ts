
import { PrismaClient, Donor } from '@prisma/client';

const prisma = new PrismaClient();

export interface DonorProfileInput {
    firstName?: string;
    lastName?: string;
    phoneNumber?: string;
    donorType?: 'INDIVIDUAL' | 'ORGANIZATION';
    organizationName?: string | null;
    addressLine1?: string;
    addressLine2?: string | null;
    province?: string;
    district?: string;
    city?: string;
    latitude?: number | null;
    longitude?: number | null;
    notes?: string | null;
}

// ====================== CREATE DONOR PROFILE ======================

export const createDonorProfile = async (
    customUserId: string,
    profileData: DonorProfileInput
): Promise<Donor> => {

    const user = await prisma.user.findUnique({
        where: { customUserId }
    });

    if (!user) {
        throw new Error('User not found');
    }

    if (user.roleCode !== 'D') {
        throw new Error('Only donor users can create a donor profile');
    }

    const existingProfile = await prisma.donor.findUnique({
        where: { customUserId }
    });

    if (existingProfile) {
        throw new Error('Donor profile already exists');
    }

    validateDonorProfile(profileData, true);

    return prisma.donor.create({
        data: {
            customUserId,
            firstName: profileData.firstName!.trim(),
            lastName: profileData.lastName!.trim(),
            phoneNumber: profileData.phoneNumber!.trim(),
            donorType: profileData.donorType!,
            organizationName:
                profileData.donorType === 'ORGANIZATION'
                    ? profileData.organizationName!.trim()
                    : null,
            addressLine1: profileData.addressLine1!.trim(),
            addressLine2: profileData.addressLine2?.trim() || null,
            province: profileData.province!.trim(),
            district: profileData.district!.trim(),
            city: profileData.city!.trim(),
            latitude: profileData.latitude ?? null,
            longitude: profileData.longitude ?? null,
            notes: profileData.notes?.trim() || null
        }
    });
};


// ====================== GET DONOR PROFILE ======================

export const getDonorProfile = async (
    customUserId: string
): Promise<Donor | null> => {

    return prisma.donor.findUnique({
        where: { customUserId }
    });
};


// ====================== UPDATE DONOR PROFILE ======================

export const updateDonorProfile = async (
    customUserId: string,
    profileData: DonorProfileInput
): Promise<Donor> => {

    const existingProfile = await prisma.donor.findUnique({
        where: { customUserId }
    });

    if (!existingProfile) {
        throw new Error('Donor profile not found');
    }

    validateDonorProfile(profileData, false);

    const donorType = profileData.donorType ?? existingProfile.donorType;

    const organizationName =
        donorType === 'ORGANIZATION'
            ? (
                profileData.organizationName !== undefined
                    ? profileData.organizationName?.trim() || null
                    : existingProfile.organizationName
            )
            : null;

    if (
        donorType === 'ORGANIZATION' &&
        !organizationName
    ) {
        throw new Error(
            'Organization name is required for organization donors'
        );
    }

    return prisma.donor.update({
        where: { customUserId },
        data: {
            ...(profileData.firstName !== undefined && {
                firstName: profileData.firstName.trim()
            }),
            ...(profileData.lastName !== undefined && {
                lastName: profileData.lastName.trim()
            }),
            ...(profileData.phoneNumber !== undefined && {
                phoneNumber: profileData.phoneNumber.trim()
            }),
            ...(profileData.donorType !== undefined && {
                donorType: profileData.donorType
            }),
            organizationName,
            ...(profileData.addressLine1 !== undefined && {
                addressLine1: profileData.addressLine1.trim()
            }),
            ...(profileData.addressLine2 !== undefined && {
                addressLine2: profileData.addressLine2?.trim() || null
            }),
            ...(profileData.province !== undefined && {
                province: profileData.province.trim()
            }),
            ...(profileData.district !== undefined && {
                district: profileData.district.trim()
            }),
            ...(profileData.city !== undefined && {
                city: profileData.city.trim()
            }),
            ...(profileData.latitude !== undefined && {
                latitude: profileData.latitude
            }),
            ...(profileData.longitude !== undefined && {
                longitude: profileData.longitude
            }),
            ...(profileData.notes !== undefined && {
                notes: profileData.notes?.trim() || null
            })
        }
    });
};


// ====================== CHECK DONOR PROFILE STATUS ======================

export const getDonorProfileStatus = async (
    customUserId: string
) => {

    const user = await prisma.user.findUnique({
        where: { customUserId }
    });

    if (!user) {
        throw new Error('User not found');
    }

    if (user.roleCode !== 'D') {
        return {
            isDonor: false,
            profileCompleted: true,
            profile: null
        };
    }

    const profile = await prisma.donor.findUnique({
        where: { customUserId }
    });

    return {
        isDonor: true,
        profileCompleted: !!profile,
        profile
    };
};


// ====================== VALIDATE DONOR PROFILE ======================

const validateDonorProfile = (
    profileData: DonorProfileInput,
    isCreating: boolean
): void => {

    const requiredFields: (keyof DonorProfileInput)[] = [
        'firstName',
        'lastName',
        'phoneNumber',
        'donorType',
        'addressLine1',
        'province',
        'district',
        'city'
    ];

    if (isCreating) {
        for (const field of requiredFields) {
            const value = profileData[field];

            if (
                value === undefined ||
                value === null ||
                (typeof value === 'string' && !value.trim())
            ) {
                throw new Error(`${field} is required`);
            }
        }
    }

    if (
        profileData.donorType !== undefined &&
        !['INDIVIDUAL', 'ORGANIZATION'].includes(profileData.donorType)
    ) {
        throw new Error('Invalid donor type');
    }

    if (
        profileData.donorType === 'ORGANIZATION' &&
        !profileData.organizationName?.trim()
    ) {
        throw new Error(
            'Organization name is required for organization donors'
        );
    }

    if (
        profileData.latitude !== undefined &&
        profileData.latitude !== null &&
        (
            !Number.isFinite(profileData.latitude) ||
            profileData.latitude < -90 ||
            profileData.latitude > 90
        )
    ) {
        throw new Error('Latitude must be between -90 and 90');
    }

    if (
        profileData.longitude !== undefined &&
        profileData.longitude !== null &&
        (
            !Number.isFinite(profileData.longitude) ||
            profileData.longitude < -180 ||
            profileData.longitude > 180
        )
    ) {
        throw new Error('Longitude must be between -180 and 180');
    }

    if (
        (profileData.latitude === null && profileData.longitude !== undefined && profileData.longitude !== null) ||
        (profileData.longitude === null && profileData.latitude !== undefined && profileData.latitude !== null)
    ) {
        throw new Error('Latitude and longitude must be provided together');
    }
};
