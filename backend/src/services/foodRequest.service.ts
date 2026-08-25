import { PrismaClient, FoodRequest } from '@prisma/client';
import { CreateFoodRequestInput } from '../validators/foodRequest.validator';

const prisma = new PrismaClient();

// Generate sequential customRequestId (e.g. RQ1, RQ2, ...)
const generateSequentialCustomRequestId = async (): Promise<string> => {
    const lastRequest = await prisma.foodRequest.findFirst({
        orderBy: { createdAt: 'desc' }
    });

    let nextNumber = 1;
    if (lastRequest && lastRequest.customRequestId) {
        const lastNumber = parseInt(lastRequest.customRequestId.replace('RQ', ''), 10);
        if (!isNaN(lastNumber)) {
            nextNumber = lastNumber + 1;
        }
    }

    return `RQ${nextNumber}`;
};

// Create a new recipient food request (status defaults to PENDING)
export const createFoodRequest = async (
    data: CreateFoodRequestInput,
    recipient: { customUserId: string; email?: string }
): Promise<FoodRequest> => {
    const customRequestId = await generateSequentialCustomRequestId();

    return prisma.foodRequest.create({
        data: {
            customRequestId,
            recipientId: recipient.customUserId,
            recipientEmail: recipient.email || null,
            recipientName: data.recipientName ? data.recipientName.trim() : null,
            recipientContact: data.recipientContact ? data.recipientContact.trim() : null,
            deliveryAddress: data.deliveryAddress ? data.deliveryAddress.trim() : null,
            donationId: data.donationId ? data.donationId.trim() : null,
            foodItem: data.foodItem!.trim(),
            quantityRequested: data.quantityRequested!.trim(),
            notes: data.notes ? data.notes.trim() : null,
            status: 'PENDING'
        }
    });
};

// Retrieve all pending food requests for NGO Coordinator review
export const getPendingFoodRequests = async (): Promise<FoodRequest[]> => {
    return prisma.foodRequest.findMany({
        where: { status: 'PENDING' },
        orderBy: { createdAt: 'desc' }
    });
};

// Retrieve all food requests with optional status or recipient filter
export const getAllFoodRequests = async (filter?: { status?: string; recipientId?: string }): Promise<FoodRequest[]> => {
    const where: any = {};
    if (filter?.status) {
        where.status = filter.status.toUpperCase();
    }
    if (filter?.recipientId) {
        where.recipientId = filter.recipientId;
    }

    return prisma.foodRequest.findMany({
        where,
        orderBy: { createdAt: 'desc' }
    });
};

// Get single food request details by ID or customRequestId
export const getFoodRequestById = async (id: string): Promise<FoodRequest> => {
    let request = await prisma.foodRequest.findUnique({
        where: { id }
    });

    if (!request) {
        request = await prisma.foodRequest.findUnique({
            where: { customRequestId: id }
        });
    }

    if (!request) {
        throw new Error('Food request not found');
    }

    return request;
};

// Approve a food request (Only for PENDING status)
export const approveFoodRequest = async (
    id: string,
    coordinatorCustomUserId: string
): Promise<FoodRequest> => {
    const request = await getFoodRequestById(id);

    if (request.status !== 'PENDING') {
        throw new Error(`Cannot approve request with status '${request.status}'. Only pending requests can be approved.`);
    }

    return prisma.foodRequest.update({
        where: { id: request.id },
        data: {
            status: 'APPROVED',
            rejectionReason: null,
            reviewedBy: coordinatorCustomUserId,
            reviewedAt: new Date()
        }
    });
};

// Reject a food request with a reason (Only for PENDING status)
export const rejectFoodRequest = async (
    id: string,
    rejectionReason: string,
    coordinatorCustomUserId: string
): Promise<FoodRequest> => {
    if (!rejectionReason || typeof rejectionReason !== 'string' || rejectionReason.trim().length === 0) {
        throw new Error('Rejection reason is required');
    }

    const request = await getFoodRequestById(id);

    if (request.status !== 'PENDING') {
        throw new Error(`Cannot reject request with status '${request.status}'. Only pending requests can be rejected.`);
    }

    return prisma.foodRequest.update({
        where: { id: request.id },
        data: {
            status: 'REJECTED',
            rejectionReason: rejectionReason.trim(),
            reviewedBy: coordinatorCustomUserId,
            reviewedAt: new Date()
        }
    });
};
