import { PrismaClient, Donation } from '@prisma/client';
import { CreateDonationInput } from '../validators/donation.validator';

const prisma = new PrismaClient();

// Generate sequential customDonationId (e.g. FD1, FD2, ...)
const generateSequentialCustomDonationId = async (): Promise<string> => {
    const lastDonation = await prisma.donation.findFirst({
        orderBy: { createdAt: 'desc' }
    });

    let nextNumber = 1;
    if (lastDonation && lastDonation.customDonationId) {
        const lastNumber = parseInt(lastDonation.customDonationId.replace('FD', ''), 10);
        if (!isNaN(lastNumber)) {
            nextNumber = lastNumber + 1;
        }
    }

    return `FD${nextNumber}`;
};

// Create a new food donation (status defaults to PENDING)
export const createDonation = async (
    data: CreateDonationInput,
    donor: { customUserId: string; email?: string }
): Promise<Donation> => {
    const customDonationId = await generateSequentialCustomDonationId();

    return prisma.donation.create({
        data: {
            customDonationId,
            title: data.title!.trim(),
            description: data.description ? data.description.trim() : null,
            foodType: data.foodType ? data.foodType.trim() : null,
            quantity: data.quantity!.trim(),
            unit: data.unit ? data.unit.trim() : null,
            expiryDate: data.expiryDate ? new Date(data.expiryDate) : null,
            pickupAddress: data.pickupAddress ? data.pickupAddress.trim() : null,
            contactNumber: data.contactNumber ? data.contactNumber.trim() : null,
            donorId: donor.customUserId,
            donorEmail: donor.email || null,
            status: 'PENDING'
        }
    });
};

// Retrieve all pending food donations for NGO Coordinator review
export const getPendingDonations = async (): Promise<Donation[]> => {
    return prisma.donation.findMany({
        where: { status: 'PENDING' },
        orderBy: { createdAt: 'desc' }
    });
};

// Retrieve all food donations (with optional status filter)
export const getAllDonations = async (filter?: { status?: string; donorId?: string }): Promise<Donation[]> => {
    const where: any = {};
    if (filter?.status) {
        where.status = filter.status.toUpperCase();
    }
    if (filter?.donorId) {
        where.donorId = filter.donorId;
    }

    return prisma.donation.findMany({
        where,
        orderBy: { createdAt: 'desc' }
    });
};

// Get single donation details by ID or customDonationId
export const getDonationById = async (id: string): Promise<Donation> => {
    // Check by primary key MongoDB ObjectId or customDonationId
    let donation = await prisma.donation.findUnique({
        where: { id }
    });

    if (!donation) {
        donation = await prisma.donation.findUnique({
            where: { customDonationId: id }
        });
    }

    if (!donation) {
        throw new Error('Donation not found');
    }

    return donation;
};

// Approve a food donation (Only for PENDING status)
export const approveDonation = async (
    id: string,
    coordinatorCustomUserId: string
): Promise<Donation> => {
    const donation = await getDonationById(id);

    if (donation.status !== 'PENDING') {
        throw new Error(`Cannot approve donation with status '${donation.status}'. Only pending donations can be approved.`);
    }

    return prisma.donation.update({
        where: { id: donation.id },
        data: {
            status: 'APPROVED',
            rejectionReason: null,
            reviewedBy: coordinatorCustomUserId,
            reviewedAt: new Date()
        }
    });
};

// Reject a food donation with a reason (Only for PENDING status)
export const rejectDonation = async (
    id: string,
    rejectionReason: string,
    coordinatorCustomUserId: string
): Promise<Donation> => {
    if (!rejectionReason || typeof rejectionReason !== 'string' || rejectionReason.trim().length === 0) {
        throw new Error('Rejection reason is required');
    }

    const donation = await getDonationById(id);

    if (donation.status !== 'PENDING') {
        throw new Error(`Cannot reject donation with status '${donation.status}'. Only pending donations can be rejected.`);
    }

    return prisma.donation.update({
        where: { id: donation.id },
        data: {
            status: 'REJECTED',
            rejectionReason: rejectionReason.trim(),
            reviewedBy: coordinatorCustomUserId,
            reviewedAt: new Date()
        }
    });
};
