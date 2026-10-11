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

    let recipientName = data.recipientName ? data.recipientName.trim() : null;
    let recipientContact = data.recipientContact ? data.recipientContact.trim() : null;
    let deliveryAddress = data.deliveryAddress ? data.deliveryAddress.trim() : null;

    // Auto-resolve recipient contact and address from Recipient profile if omitted or minimal
    if (!recipientName || recipientName === recipient.customUserId || !recipientContact || !deliveryAddress) {
        try {
            const profile = await prisma.recipient.findUnique({
                where: { customUserId: recipient.customUserId }
            });
            if (profile) {
                if (!recipientName || recipientName === recipient.customUserId) {
                    recipientName = `${profile.firstName} ${profile.lastName}`.trim();
                }
                if (!recipientContact) {
                    recipientContact = profile.phoneNumber;
                }
                if (!deliveryAddress) {
                    deliveryAddress = [
                        profile.addressLine1,
                        profile.addressLine2,
                        profile.city,
                        profile.district
                    ].filter(Boolean).join(', ');
                }
            }
        } catch (_) {}
    }

    return prisma.foodRequest.create({
        data: {
            customRequestId,
            recipientId: recipient.customUserId,
            recipientEmail: recipient.email || null,
            recipientName,
            recipientContact,
            deliveryAddress,
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
    const conditions: any[] = [];

    if (filter?.status) {
        const s = filter.status.toUpperCase();
        if (s === 'APPROVED' || s === 'ACCEPTED') {
            conditions.push({ status: { in: ['APPROVED', 'ACCEPTED'] } });
        } else {
            conditions.push({ status: s });
        }
    }

    if (filter?.recipientId && filter.recipientId.trim().length > 0) {
        const rId = filter.recipientId.trim();
        const orConditions: any[] = [
            { recipientId: rId },
            { recipientEmail: rId }
        ];

        try {
            const u = await prisma.user.findUnique({
                where: { customUserId: rId },
                select: { email: true, id: true }
            });
            if (u?.email) orConditions.push({ recipientEmail: u.email });
            if (u?.id) orConditions.push({ recipientId: u.id });
        } catch (_) {}

        conditions.push({ OR: orConditions });
    }

    const where = conditions.length > 0 ? { AND: conditions } : {};

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
// Creates an unassigned Delivery task with status PENDING_ASSIGNMENT for volunteer pickup
export const approveFoodRequest = async (
    id: string,
    coordinatorCustomUserId: string
): Promise<FoodRequest> => {
    const request = await getFoodRequestById(id);

    if (request.status !== 'PENDING') {
        throw new Error(`Cannot approve request with status '${request.status}'. Only pending requests can be approved.`);
    }

    const updatedRequest = await prisma.foodRequest.update({
        where: { id: request.id },
        data: {
            status: 'APPROVED',
            rejectionReason: null,
            reviewedBy: coordinatorCustomUserId,
            reviewedAt: new Date()
        }
    });

    // Check if an active delivery task already exists to prevent duplicate delivery tasks
    try {
        const existingDelivery = await prisma.delivery.findFirst({
            where: {
                recipientId: request.recipientId,
                foodItem: request.foodItem,
                status: {
                    in: [
                        'PENDING_ASSIGNMENT',
                        'ASSIGNED',
                        'ACCEPTED',
                        'PICKED_UP',
                        'IN_TRANSIT'
                    ]
                }
            }
        });

        if (!existingDelivery) {
            // Retrieve recipient profile for drop-off details and coordinates
            const recipientProfile = await prisma.recipient.findUnique({
                where: { customUserId: request.recipientId }
            });

            let dropoffAddress = request.deliveryAddress?.trim() || null;
            let dropoffLatitude = recipientProfile?.latitude || null;
            let dropoffLongitude = recipientProfile?.longitude || null;

            if (!dropoffAddress && recipientProfile) {
                dropoffAddress = [
                    recipientProfile.addressLine1,
                    recipientProfile.addressLine2,
                    recipientProfile.city,
                    recipientProfile.district
                ].filter(Boolean).join(', ');
            }

            // Retrieve linked donation info if available
            let donorId = 'COMMUNITY_DONOR';
            let pickupAddress: string | null = 'Community Food Surplus Hub';
            let foodExpiryDate: Date | null = null;
            let pickupLatitude: number | null = null;
            let pickupLongitude: number | null = null;

            if (request.donationId) {
                try {
                    const donation = await prisma.foodDonation.findUnique({
                        where: { id: request.donationId }
                    });
                    if (donation) {
                        donorId = donation.donorId;
                        pickupAddress = donation.pickupLocation || pickupAddress;
                        foodExpiryDate = donation.expiryDate || null;
                    }
                } catch (_) {}
            }

            // Parse foodQuantityKg from quantityRequested string
            let foodQuantityKg = 1.0;
            if (request.quantityRequested) {
                const parsedNum = parseFloat(request.quantityRequested.replace(/[^0-9.]/g, ''));
                if (!isNaN(parsedNum) && parsedNum > 0) {
                    foodQuantityKg = parsedNum;
                }
            }

            // Create delivery with status PENDING_ASSIGNMENT (unassigned for volunteers)
            await prisma.delivery.create({
                data: {
                    volunteerId: null,
                    donorId,
                    recipientId: request.recipientId,
                    foodItem: request.foodItem,
                    foodQuantityKg,
                    foodExpiryDate,
                    pickupAddress,
                    pickupLatitude,
                    pickupLongitude,
                    dropoffAddress,
                    dropoffLatitude,
                    dropoffLongitude,
                    status: 'PENDING_ASSIGNMENT'
                }
            });
        }
    } catch (deliveryError) {
        // Log delivery creation error but ensure approval succeeds
        console.error('Error creating delivery for approved request:', deliveryError);
    }

    return updatedRequest;
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

    const updatedRequest = await prisma.foodRequest.update({
        where: { id: request.id },
        data: {
            status: 'REJECTED',
            rejectionReason: rejectionReason.trim(),
            reviewedBy: coordinatorCustomUserId,
            reviewedAt: new Date()
        }
    });

    // Cancel any unassigned delivery task associated with this request
    try {
        await prisma.delivery.updateMany({
            where: {
                recipientId: request.recipientId,
                foodItem: request.foodItem,
                status: 'PENDING_ASSIGNMENT'
            },
            data: {
                status: 'CANCELLED',
                rejectionReason: `Request rejected by NGO Coordinator: ${rejectionReason.trim()}`
            }
        });
    } catch (_) {}

    return updatedRequest;
};
