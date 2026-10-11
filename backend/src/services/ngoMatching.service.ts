import { DonationStatus, PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

type DonationCandidate = {
    id: string;
    category: string;
    pickupLocation: string;
    expiryDate: Date;
    pickupDateTime: Date;
};

type RecipientCandidate = {
    customUserId: string;
    city: string;
    district: string;
};

const normalise = (value: string): string =>
    value.toLowerCase().replace(/[^a-z0-9]+/g, ' ').trim();

/** A food category is compatible when either value contains the other. */
export const isCategoryMatch = (category: string, foodItem: string): boolean => {
    const normalisedCategory = normalise(category);
    const normalisedFoodItem = normalise(foodItem);
    return normalisedCategory.length > 0 &&
        normalisedFoodItem.length > 0 &&
        (normalisedFoodItem.includes(normalisedCategory) ||
            normalisedCategory.includes(normalisedFoodItem));
};

/** A pickup location is compatible when it contains the recipient city or district. */
export const isLocationMatch = (
    pickupLocation: string,
    recipient: RecipientCandidate
): boolean => {
    const normalisedPickupLocation = normalise(pickupLocation);
    return [recipient.city, recipient.district]
        .map(normalise)
        .filter((area) => area.length > 0)
        .some((area) => normalisedPickupLocation.includes(area));
};

export const isDonationAvailable = (
    donation: Pick<DonationCandidate, 'expiryDate' | 'pickupDateTime'>,
    now = new Date()
): boolean => donation.expiryDate > now && donation.pickupDateTime >= now;

export const generateFoodMatches = async () => {
    const now = new Date();
    const [donations, requests] = await Promise.all([
        prisma.foodDonation.findMany({
            where: {
                // The NGO review flow marks accepted submissions APPROVED.
                // Older/legacy donations may already be AVAILABLE, so both are
                // eligible for matching as long as their dates are still valid.
                status: { in: [DonationStatus.APPROVED, DonationStatus.AVAILABLE] },
                expiryDate: { gt: now },
                pickupDateTime: { gte: now }
            },
            select: {
                id: true,
                category: true,
                pickupLocation: true,
                expiryDate: true,
                pickupDateTime: true
            }
        }),
        prisma.foodRequest.findMany({
            where: { status: 'APPROVED' },
            select: { id: true, recipientId: true, foodItem: true }
        })
    ]);

    const recipientIds = [...new Set(requests.map((request) => request.recipientId))];
    if (donations.length === 0 || recipientIds.length === 0) {
        return [];
    }

    const [recipients, recipientUsers] = await Promise.all([
        prisma.recipient.findMany({
            where: { customUserId: { in: recipientIds } },
            select: { customUserId: true, city: true, district: true }
        }),
        prisma.user.findMany({
            where: { customUserId: { in: recipientIds }, roleCode: 'R' },
            select: { customUserId: true }
        })
    ]);

    const eligibleRecipientIds = new Set(recipientUsers.map((user) => user.customUserId));
    const recipientById = new Map(
        recipients
            .filter((recipient) => eligibleRecipientIds.has(recipient.customUserId))
            .map((recipient) => [recipient.customUserId, recipient])
    );

    const matchOperations = donations.flatMap((donation) =>
        requests.flatMap((request) => {
            const recipient = recipientById.get(request.recipientId);
            const locationMatched = !!recipient &&
                isLocationMatch(donation.pickupLocation, recipient);
            if (!recipient ||
                !isDonationAvailable(donation, now) ||
                !isCategoryMatch(donation.category, request.foodItem)) {
                return [];
            }
            // Same category in another area is still useful, but ranked lower.
            const score = locationMatched ? 100 : 60;

            return prisma.foodMatch.upsert({
                where: {
                    donationId_foodRequestId: {
                        donationId: donation.id,
                        foodRequestId: request.id
                    }
                },
                create: {
                    donationId: donation.id,
                    foodRequestId: request.id,
                    recipientId: request.recipientId,
                    categoryMatched: true,
                    locationMatched,
                    availabilityCheckedAt: now,
                    eligibilityCheckedAt: now,
                    score,
                    status: 'SUGGESTED'
                },
                update: {
                    categoryMatched: true,
                    locationMatched,
                    availabilityCheckedAt: now,
                    eligibilityCheckedAt: now,
                    score
                }
            });
        })
    );

    return Promise.all(matchOperations);
};

export const getFoodMatches = async () =>
    prisma.foodMatch.findMany({
        include: {
            donation: {
                select: {
                    id: true,
                    category: true,
                    quantity: true,
                    quantityUnit: true,
                    pickupLocation: true,
                    pickupDateTime: true,
                    expiryDate: true
                }
            },
            foodRequest: {
                select: {
                    id: true,
                    customRequestId: true,
                    recipientName: true,
                    recipientEmail: true,
                    foodItem: true,
                    quantityRequested: true,
                    deliveryAddress: true
                }
            }
        },
        orderBy: [{ score: 'desc' }, { matchedAt: 'desc' }]
    });
