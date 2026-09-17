import {
    DonationStatus,
    Prisma,
    PrismaClient
} from '@prisma/client';

const prisma = new PrismaClient();

export type RecipientDonationAvailability =
    | 'available'
    | 'unavailable'
    | 'all';

export interface RecipientDonationFilters {
    category?: string;
    location?: string;
    availability: RecipientDonationAvailability;
}

const recipientDonationSelect = {
    id: true,
    category: true,
    quantity: true,
    quantityUnit: true,
    description: true,
    expiryDate: true,
    imageUrl: true,
    pickupLocation: true,
    pickupDateTime: true,
    status: true,
    createdAt: true,
    updatedAt: true
} satisfies Prisma.FoodDonationSelect;

type RecipientDonation = Prisma.FoodDonationGetPayload<{
    select: typeof recipientDonationSelect;
}>;

const getAvailableDonationWhere = (
    now: Date
): Prisma.FoodDonationWhereInput => ({
    status: DonationStatus.AVAILABLE,
    expiryDate: {
        gt: now
    },
    pickupDateTime: {
        gte: now
    }
});

const buildDonationWhere = (
    filters: RecipientDonationFilters
): Prisma.FoodDonationWhereInput => {
    const where: Prisma.FoodDonationWhereInput = {};
    const now = new Date();

    if (filters.category) {
        where.category = {
            contains: filters.category,
            mode: 'insensitive'
        };
    }

    if (filters.location) {
        where.pickupLocation = {
            contains: filters.location,
            mode: 'insensitive'
        };
    }

    if (filters.availability === 'available') {
        Object.assign(where, getAvailableDonationWhere(now));
    }

    if (filters.availability === 'unavailable') {
        where.OR = [
            {
                status: {
                    not: DonationStatus.AVAILABLE
                }
            },
            {
                expiryDate: {
                    lte: now
                }
            },
            {
                pickupDateTime: {
                    lt: now
                }
            }
        ];
    }

    return where;
};

export const getAvailableRecipientDonations = async (
    filters: RecipientDonationFilters
): Promise<RecipientDonation[]> => {
    return prisma.foodDonation.findMany({
        where: buildDonationWhere(filters),
        select: recipientDonationSelect,
        orderBy: [
            {
                pickupDateTime: 'asc'
            },
            {
                createdAt: 'desc'
            }
        ]
    });
};

export const getRecipientDonationById = async (
    donationId: string
): Promise<RecipientDonation> => {
    if (!/^[a-fA-F0-9]{24}$/.test(donationId)) {
        throw new Error('Food donation not found');
    }

    const now = new Date();

    const donation = await prisma.foodDonation.findFirst({
        where: {
            id: donationId,
            ...getAvailableDonationWhere(now)
        },
        select: recipientDonationSelect
    });

    if (!donation) {
        throw new Error('Food donation not found');
    }

    return donation;
};