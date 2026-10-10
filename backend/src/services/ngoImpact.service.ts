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
    const donationStatusCounts = donations.reduce<Record<string, number>>(
        (counts, donation) => {
            counts[donation.status] = (counts[donation.status] ?? 0) + 1;
            return counts;
        },
        {}
    );

    return {
        donationStatistics: {
            total: donations.length,
            approved: donations.filter((donation) =>
                donation.status === DonationStatus.APPROVED
            ).length,
            // Delivery records currently have no donationId, so this is an
            // exact delivery-record count, not a distinct donation count.
            completedDeliveryRecords: deliveredDeliveries.length,
            byStatus: donationStatusCounts,
            quantityByUnit: toQuantitySummary(donations)
        },
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

/** Aggregate assigned delivery activity for the NGO coordinator dashboard. */
export const getVolunteerActivityAnalytics = async () => {
    const activeStatuses = new Set<DeliveryStatus>([
        DeliveryStatus.ACCEPTED,
        DeliveryStatus.PICKED_UP,
        DeliveryStatus.IN_TRANSIT
    ]);
    const [deliveries, availabilityRecords] = await Promise.all([
        prisma.delivery.findMany({
            where: { volunteerId: { not: null } },
            select: {
                volunteerId: true,
                status: true,
                deliveredAt: true
            }
        }),
        prisma.volunteerAvailability.findMany({
            select: { volunteerId: true, status: true }
        })
    ]);

    const assignedVolunteerIds = new Set<string>();
    const activityByVolunteer = new Map<string, {
        totalDeliveries: number;
        completedDeliveries: number;
        activeDeliveries: number;
        lastDeliveredAt: Date | null;
    }>();
    const deliveryStatusCounts: Record<string, number> = {};

    for (const delivery of deliveries) {
        if (!delivery.volunteerId) continue;
        const volunteerId = delivery.volunteerId;
        assignedVolunteerIds.add(volunteerId);
        deliveryStatusCounts[delivery.status] =
            (deliveryStatusCounts[delivery.status] ?? 0) + 1;

        const activity = activityByVolunteer.get(volunteerId) ?? {
            totalDeliveries: 0,
            completedDeliveries: 0,
            activeDeliveries: 0,
            lastDeliveredAt: null
        };
        activity.totalDeliveries += 1;
        if (delivery.status === DeliveryStatus.DELIVERED) {
            activity.completedDeliveries += 1;
            if (
                delivery.deliveredAt &&
                (!activity.lastDeliveredAt || delivery.deliveredAt > activity.lastDeliveredAt)
            ) {
                activity.lastDeliveredAt = delivery.deliveredAt;
            }
        }
        if (activeStatuses.has(delivery.status)) {
            activity.activeDeliveries += 1;
        }
        activityByVolunteer.set(volunteerId, activity);
    }

    for (const record of availabilityRecords) {
        assignedVolunteerIds.add(record.volunteerId);
    }

    const volunteerActivity = [...activityByVolunteer.entries()]
        .map(([volunteerId, activity]) => ({
            volunteerId,
            ...activity,
            lastDeliveredAt: activity.lastDeliveredAt?.toISOString() ?? null
        }))
        .sort((a, b) =>
            b.completedDeliveries - a.completedDeliveries ||
            b.totalDeliveries - a.totalDeliveries
        );

    return {
        totalVolunteers: assignedVolunteerIds.size,
        availableVolunteers: availabilityRecords.filter(
            (record) => record.status === 'AVAILABLE'
        ).length,
        totalAssignedDeliveries: deliveries.length,
        completedDeliveries: deliveries.filter(
            (delivery) => delivery.status === DeliveryStatus.DELIVERED
        ).length,
        activeDeliveries: deliveries.filter((delivery) =>
            activeStatuses.has(delivery.status)
        ).length,
        deliveryStatusCounts,
        volunteers: volunteerActivity
    };
};
