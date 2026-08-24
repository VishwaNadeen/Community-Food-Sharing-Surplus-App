import { DonationStatus, PrismaClient, QuantityUnit } from '@prisma/client';
import { DonationInput } from '../validators/donation.validator';

const prisma = new PrismaClient();

export const createDonation = async (
    donorCustomUserId: string,
    donationData: DonationInput,
    imageUrl?: string
) => {
    const donor = await prisma.user.findUnique({
        where: {
            customUserId: donorCustomUserId
        }
    });

    if (!donor) {
        throw new Error('Donor not found');
    }

    return prisma.foodDonation.create({
        data: {
            donorId: donor.id,
            category: donationData.category!.trim(),
            quantity: donationData.quantity!,
            quantityUnit: donationData.quantityUnit!.toUpperCase() as QuantityUnit,
            description: donationData.description!.trim(),
            expiryDate: new Date(donationData.expiryDate!),
            imageUrl: imageUrl ?? null,
            pickupLocation: donationData.pickupLocation!.trim(),
            pickupDateTime: new Date(donationData.pickupDateTime!),
            status: DonationStatus.AVAILABLE
        }
    });
};

export const getDonationsByDonor = async (
    donorCustomUserId: string
) => {
    const donor = await prisma.user.findUnique({
        where: {
            customUserId: donorCustomUserId
        }
    });

    if (!donor) {
        throw new Error('Donor not found');
    }

    return prisma.foodDonation.findMany({
        where: {
            donorId: donor.id
        },
        orderBy: {
            createdAt: 'desc'
        }
    });
};

export const updateDonation = async (
    donationId: string,
    donorCustomUserId: string,
    donationData: DonationInput,
    imageUrl?: string
) => {
    const donor = await prisma.user.findUnique({
        where: {
            customUserId: donorCustomUserId
        }
    });

    if (!donor) {
        throw new Error('Donor not found');
    }

    const donation = await prisma.foodDonation.findUnique({
        where: {
            id: donationId
        }
    });

    if (!donation) {
        throw new Error('Donation not found');
    }

    if (donation.donorId !== donor.id) {
        throw new Error('You are not allowed to edit this donation');
    }

    if (donation.status !== DonationStatus.AVAILABLE) {
        throw new Error('Only available donations can be edited');
    }

    const updateData: any = {};

    if (donationData.category !== undefined) {
        updateData.category = donationData.category.trim();
    }

    if (donationData.quantity !== undefined) {
        updateData.quantity = donationData.quantity;
    }

    if (donationData.quantityUnit !== undefined) {
        updateData.quantityUnit =
            donationData.quantityUnit.toUpperCase() as QuantityUnit;
    }

    if (donationData.description !== undefined) {
        updateData.description = donationData.description.trim();
    }

    if (donationData.expiryDate !== undefined) {
        updateData.expiryDate = new Date(donationData.expiryDate);
    }

    if (donationData.pickupLocation !== undefined) {
        updateData.pickupLocation = donationData.pickupLocation.trim();
    }

    if (donationData.pickupDateTime !== undefined) {
        updateData.pickupDateTime =
            new Date(donationData.pickupDateTime);
    }

    if (imageUrl !== undefined) {
        updateData.imageUrl = imageUrl;
    }

    return prisma.foodDonation.update({
        where: {
            id: donationId
        },
        data: updateData
    });
};