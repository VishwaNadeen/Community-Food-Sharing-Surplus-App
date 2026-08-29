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
            status: DonationStatus.PENDING
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

    // A donation can be edited while it is still pending review.
    if (donation.status !== DonationStatus.PENDING) {
        throw new Error('Only pending donations can be edited');
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

export const cancelDonation = async (
    donationId: string,
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

    const donation = await prisma.foodDonation.findUnique({
        where: {
            id: donationId
        }
    });

    if (!donation) {
        throw new Error('Donation not found');
    }

    if (donation.donorId !== donor.id) {
        throw new Error('You are not allowed to cancel this donation');
    }

    // A donor may cancel a donation while it is still pending approval.
    if (donation.status !== DonationStatus.PENDING) {
        throw new Error('Only pending donations can be cancelled');
    }

    return prisma.foodDonation.update({
        where: {
            id: donationId
        },
        data: {
            status: DonationStatus.CANCELLED
        }
    });
};

// Retrieve all pending food donations for NGO Coordinator review
export const getPendingDonations = async () => {
    return prisma.foodDonation.findMany({
        where: {
            status: DonationStatus.PENDING
        },
        orderBy: {
            createdAt: 'desc'
        }
    });
};

// Get single donation details by ID
export const getDonationById = async (donationId: string) => {
    const donation = await prisma.foodDonation.findUnique({
        where: {
            id: donationId
        }
    });

    if (!donation) {
        throw new Error('Donation not found');
    }

    return donation;
};

// Approve a food donation (Only for PENDING status)
export const approveDonation = async (
    donationId: string,
    coordinatorCustomUserId: string
) => {
    const donation = await getDonationById(donationId);

    if (donation.status !== DonationStatus.PENDING) {
        throw new Error(`Cannot approve donation with status '${donation.status}'. Only pending donations can be approved.`);
    }

    return prisma.foodDonation.update({
        where: {
            id: donation.id
        },
        data: {
            status: DonationStatus.APPROVED,
            rejectionReason: null,
            reviewedBy: coordinatorCustomUserId,
            reviewedAt: new Date()
        }
    });
};

// Reject a food donation with a reason (Only for PENDING status)
export const rejectDonation = async (
    donationId: string,
    rejectionReason: string,
    coordinatorCustomUserId: string
) => {
    if (!rejectionReason || typeof rejectionReason !== 'string' || rejectionReason.trim().length === 0) {
        throw new Error('Rejection reason is required');
    }

    const donation = await getDonationById(donationId);

    if (donation.status !== DonationStatus.PENDING) {
        throw new Error(`Cannot reject donation with status '${donation.status}'. Only pending donations can be rejected.`);
    }

    return prisma.foodDonation.update({
        where: {
            id: donation.id
        },
        data: {
            status: DonationStatus.REJECTED,
            rejectionReason: rejectionReason.trim(),
            reviewedBy: coordinatorCustomUserId,
            reviewedAt: new Date()
        }
    });
};

// Retrieve all food donations (with optional status filter)
export const getAllDonations = async (filter?: { status?: string; donorId?: string }) => {
    const where: any = {};
    if (filter?.status) {
        where.status = filter.status.toUpperCase() as DonationStatus;
    }
    if (filter?.donorId) {
        where.donorId = filter.donorId;
    }

    return prisma.foodDonation.findMany({
        where,
        orderBy: {
            createdAt: 'desc'
        }
    });
};