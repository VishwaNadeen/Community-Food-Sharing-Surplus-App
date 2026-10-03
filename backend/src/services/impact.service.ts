import { DeliveryStatus, DonationStatus, PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

type QuantitySummary = Record<string, number>;

const toQuantitySummary = (
    donations: Array<{ quantity: number; quantityUnit: string }>
): QuantitySummary => donations.reduce<QuantitySummary>((summary, donation) => {
    summary[donation.quantityUnit] =
        (summary[donation.quantityUnit] ?? 0) + donation.quantity;
    return summary;
}, {});

/**
 * One meal is estimated from 0.5 kg of food. This is kept explicit because
 * deliveries store food weight, not individual meal counts.
 */
export const getImpactAnalytics = async () => {
    const kilogramsPerMeal = 0.5;
    const sixMonthsAgo = new Date();
    sixMonthsAgo.setMonth(sixMonthsAgo.getMonth() - 5);
    sixMonthsAgo.setDate(1);
    sixMonthsAgo.setHours(0, 0, 0, 0);

    const [donations, requests, matches, deliveredDeliveries] = await Promise.all([
        prisma.foodDonation.findMany({
            select: {
                category: true,
                quantity: true,
                quantityUnit: true,
                status: true,
                createdAt: true
            }
        }),
        prisma.foodRequest.findMany({
            select: { status: true, createdAt: true }
        }),
        prisma.foodMatch.findMany({
            select: { status: true }
        }),
        prisma.delivery.findMany({
            where: { status: DeliveryStatus.DELIVERED },
            select: {
                foodQuantityKg: true,
                volunteerId: true,
                deliveredAt: true
            }
        })
    ]);

    const redistributableStatuses = new Set<DonationStatus>([
        DonationStatus.APPROVED,
        DonationStatus.AVAILABLE,
        DonationStatus.COLLECTED
    ]);
    const redistributableDonations = donations.filter((donation) =>
        redistributableStatuses.has(donation.status)
    );

    const monthKeys: Date[] = Array.from({ length: 6 }, (_, index) => {
        const month = new Date(sixMonthsAgo);
        month.setMonth(sixMonthsAgo.getMonth() + index);
        return month;
    });
    const monthIndex = new Map(
        monthKeys.map((month, index) => [
            `${month.getFullYear()}-${month.getMonth()}`,
            index
        ])
    );
    const monthlyImpact = monthKeys.map((month) => ({
        month: month.toLocaleString('en-US', { month: 'short' }),
        donations: 0,
        requests: 0
    }));

    donations.forEach((donation) => {
        const index = monthIndex.get(
            `${donation.createdAt.getFullYear()}-${donation.createdAt.getMonth()}`
        );
        if (index !== undefined) monthlyImpact[index].donations += 1;
    });
    requests.forEach((request) => {
        const index = monthIndex.get(
            `${request.createdAt.getFullYear()}-${request.createdAt.getMonth()}`
        );
        if (index !== undefined) monthlyImpact[index].requests += 1;
    });

    const categoryTotals = donations.reduce<Record<string, number>>(
        (summary, donation) => {
            summary[donation.category] = (summary[donation.category] ?? 0) + 1;
            return summary;
        },
        {}
    );

    const deliveredFoodKg = deliveredDeliveries.reduce(
        (total, delivery) => total + delivery.foodQuantityKg,
        0
    );
    const activeVolunteerIds = new Set(
        deliveredDeliveries
            .map((delivery) => delivery.volunteerId)
            .filter((volunteerId): volunteerId is string => volunteerId !== null)
    );

    return {
        summary: {
            totalDonations: donations.length,
            approvedDonations: redistributableDonations.length,
            totalRequests: requests.length,
            approvedRequests: requests.filter((request) => request.status === 'APPROVED').length,
            suitableMatches: matches.length,
            acceptedMatches: matches.filter((match) => match.status === 'ACCEPTED').length,
            // Different quantity units must not be converted or added together.
            donatedQuantityByUnit: toQuantitySummary(donations),
            // Prevented food waste must be based on completed deliveries,
            // not merely on a donation being approved.
            foodWastePreventedByUnit: { KG: deliveredFoodKg },
            mealsDelivered: Math.floor(deliveredFoodKg / kilogramsPerMeal),
            activeVolunteers: activeVolunteerIds.size,
            completedDeliveries: deliveredDeliveries.length
        },
        monthlyImpact,
        donationsByCategory: Object.entries(categoryTotals)
            .map(([category, count]) => ({ category, count }))
            .sort((a, b) => b.count - a.count),
        dataAvailability: {
            deliveryMetricsAvailable: true,
            volunteerMetricsAvailable: true,
            note: 'Meal total is estimated using 0.5 kg per meal.'
        }
    };
};
