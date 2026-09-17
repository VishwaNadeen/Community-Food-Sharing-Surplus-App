import { PrismaClient, Recipient } from '@prisma/client';

import {
    RecipientProfileInput
} from '../validators/recipient.validator';


const prisma = new PrismaClient();


// ====================== CREATE RECIPIENT PROFILE ======================

export const createRecipientProfile = async (
    customUserId: string,
    profileData: RecipientProfileInput
): Promise<Recipient> => {

    const user = await prisma.user.findUnique({
        where: {
            customUserId
        }
    });

    if (!user) {
        throw new Error('User not found');
    }

    if (user.roleCode !== 'R') {
        throw new Error(
            'Only recipient users can create a recipient profile'
        );
    }

    const existingProfile = await prisma.recipient.findUnique({
        where: {
            customUserId
        }
    });

    if (existingProfile) {
        throw new Error('Recipient profile already exists');
    }

    return prisma.recipient.create({
        data: {
            customUserId,

            firstName: profileData.firstName!.trim(),

            lastName: profileData.lastName!.trim(),

            nic: profileData.nic!.trim().toUpperCase(),

            phoneNumber: profileData.phoneNumber!.trim(),

            addressLine1: profileData.addressLine1!.trim(),

            addressLine2:
                profileData.addressLine2?.trim() || null,

            city: profileData.city!.trim(),

            district: profileData.district!.trim(),

            latitude: profileData.latitude ?? null,

            longitude: profileData.longitude ?? null,

            timeZone: profileData.timeZone!.trim(),

            language: profileData.language!.trim()
        }
    });
};


// ====================== GET RECIPIENT PROFILE ======================

export const getRecipientProfile = async (
    customUserId: string
): Promise<Recipient> => {

    const profile = await prisma.recipient.findUnique({
        where: {
            customUserId
        }
    });

    if (!profile) {
        throw new Error('Recipient profile not found');
    }

    return profile;
};


// ====================== UPDATE RECIPIENT PROFILE ======================

export const updateRecipientProfile = async (
    customUserId: string,
    profileData: RecipientProfileInput
): Promise<Recipient> => {

    const existingProfile = await prisma.recipient.findUnique({
        where: {
            customUserId
        }
    });

    if (!existingProfile) {
        throw new Error('Recipient profile not found');
    }

    return prisma.recipient.update({
        where: {
            customUserId
        },

        data: {
            ...(profileData.firstName !== undefined && {
                firstName: profileData.firstName.trim()
            }),

            ...(profileData.lastName !== undefined && {
                lastName: profileData.lastName.trim()
            }),

            ...(profileData.nic !== undefined && {
                nic: profileData.nic.trim().toUpperCase()
            }),

            ...(profileData.phoneNumber !== undefined && {
                phoneNumber: profileData.phoneNumber.trim()
            }),

            ...(profileData.addressLine1 !== undefined && {
                addressLine1: profileData.addressLine1.trim()
            }),

            ...(profileData.addressLine2 !== undefined && {
                addressLine2:
                    profileData.addressLine2.trim() || null
            }),

            ...(profileData.city !== undefined && {
                city: profileData.city.trim()
            }),

            ...(profileData.district !== undefined && {
                district: profileData.district.trim()
            }),

            ...(profileData.latitude !== undefined && {
                latitude: profileData.latitude
            }),

            ...(profileData.longitude !== undefined && {
                longitude: profileData.longitude
            }),

            ...(profileData.timeZone !== undefined && {
                timeZone: profileData.timeZone.trim()
            }),

            ...(profileData.language !== undefined && {
                language: profileData.language.trim()
            })
        }
    });
};


// ====================== DELETE RECIPIENT PROFILE ======================

export const deleteRecipientProfile = async (
    customUserId: string
): Promise<Recipient> => {

    const existingProfile = await prisma.recipient.findUnique({
        where: {
            customUserId
        }
    });

    if (!existingProfile) {
        throw new Error('Recipient profile not found');
    }

    return prisma.recipient.delete({
        where: {
            customUserId
        }
    });
};


// ====================== CHECK PROFILE STATUS ======================

export const getRecipientProfileStatus = async (
    customUserId: string
) => {

    const user = await prisma.user.findUnique({
        where: {
            customUserId
        }
    });

    if (!user) {
        throw new Error('User not found');
    }

    if (user.roleCode !== 'R') {
        return {
            isRecipient: false,
            profileCompleted: true,
            profile: null
        };
    }

    const profile = await prisma.recipient.findUnique({
        where: {
            customUserId
        }
    });

    return {
        isRecipient: true,

        profileCompleted: !!profile,

        profile
    };
};