import { DeliveryProblemStatus, DeliveryStatus, DonationStatus, PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

const ACTIVE_WINDOW_DAYS = 90;
const OBJECT_ID_PATTERN = /^[a-f\d]{24}$/i;

export class AdminValidationError extends Error {
    constructor(message: string, public readonly statusCode = 400) {
        super(message);
    }
}

type ActivityStatus = 'ACTIVE' | 'INACTIVE' | 'NEW';

/**
 * Activity is derived from real records: a partner is ACTIVE when they have
 * acted within the last 90 days, INACTIVE when older, and NEW when they have
 * not acted yet. There is no suspension/verification field in the schema.
 */
const toActivityStatus = (lastActivityAt: Date | null): ActivityStatus => {
    if (!lastActivityAt) return 'NEW';
    const cutoff = new Date();
    cutoff.setDate(cutoff.getDate() - ACTIVE_WINDOW_DAYS);
    return lastActivityAt >= cutoff ? 'ACTIVE' : 'INACTIVE';
};

const latest = (current: Date | null, candidate: Date): Date =>
    !current || candidate > current ? candidate : current;

export const getAdminOverview = async () => {
    const startOfMonth = new Date();
    startOfMonth.setDate(1);
    startOfMonth.setHours(0, 0, 0, 0);

    const [
        donorCount,
        recipientCount,
        availabilityRecords,
        deliveryVolunteers,
        donationsThisMonth,
        pendingDonations,
        pendingRequests,
        pendingDeliveries,
        openProblems
    ] = await Promise.all([
        prisma.user.count({ where: { roleCode: 'D' } }),
        prisma.recipient.count(),
        prisma.volunteerAvailability.findMany({ select: { volunteerId: true } }),
        prisma.delivery.findMany({
            where: { volunteerId: { not: null } },
            select: { volunteerId: true }
        }),
        prisma.foodDonation.count({ where: { createdAt: { gte: startOfMonth } } }),
        prisma.foodDonation.findMany({
            where: { status: DonationStatus.PENDING },
            orderBy: { createdAt: 'asc' },
            take: 3,
            select: { id: true, category: true, createdAt: true }
        }),
        prisma.foodRequest.findMany({
            where: { status: 'PENDING' },
            orderBy: { createdAt: 'asc' },
            take: 3,
            select: { id: true, foodItem: true, createdAt: true }
        }),
        prisma.delivery.count({ where: { status: DeliveryStatus.PENDING_ASSIGNMENT } }),
        prisma.deliveryProblem.findMany({
            where: { status: { not: DeliveryProblemStatus.RESOLVED } },
            orderBy: { createdAt: 'asc' },
            take: 3,
            select: { id: true, problemType: true, status: true, createdAt: true }
        })
    ]);

    const [pendingDonationCount, pendingRequestCount, openProblemCount] = await Promise.all([
        prisma.foodDonation.count({ where: { status: DonationStatus.PENDING } }),
        prisma.foodRequest.count({ where: { status: 'PENDING' } }),
        prisma.deliveryProblem.count({
            where: { status: { not: DeliveryProblemStatus.RESOLVED } }
        })
    ]);

    const volunteerIds = new Set<string>([
        ...availabilityRecords.map((record) => record.volunteerId),
        ...deliveryVolunteers
            .map((delivery) => delivery.volunteerId)
            .filter((volunteerId): volunteerId is string => volunteerId !== null)
    ]);

    const priorityTasks = [
        ...openProblems.map((problem) => ({
            type: 'DELIVERY_PROBLEM',
            title: `Delivery problem: ${problem.problemType}`,
            detail: problem.status === DeliveryProblemStatus.REPORTED
                ? 'New report'
                : 'Acknowledged, not yet resolved',
            priority: 'HIGH',
            createdAt: problem.createdAt.toISOString()
        })),
        ...pendingDonations.map((donation) => ({
            type: 'PENDING_DONATION',
            title: `Review ${donation.category} donation`,
            detail: 'Waiting for approval',
            priority: 'MEDIUM',
            createdAt: donation.createdAt.toISOString()
        })),
        ...pendingRequests.map((request) => ({
            type: 'PENDING_REQUEST',
            title: `Review request for ${request.foodItem}`,
            detail: 'Waiting for approval',
            priority: 'MEDIUM',
            createdAt: request.createdAt.toISOString()
        }))
    ];

    return {
        metrics: {
            donors: donorCount,
            recipients: recipientCount,
            volunteers: volunteerIds.size,
            donationsThisMonth,
            pendingDonations: pendingDonationCount,
            pendingRequests: pendingRequestCount,
            pendingDeliveries,
            openProblems: openProblemCount
        },
        priorityTasks
    };
};

export const getDonorSummaries = async () => {
    const [donors, donations] = await Promise.all([
        prisma.user.findMany({
            where: { roleCode: 'D' },
            select: { id: true, customUserId: true, email: true, createdAt: true }
        }),
        prisma.foodDonation.findMany({
            select: { donorId: true, status: true, createdAt: true }
        })
    ]);

    const statsByDonor = new Map<string, {
        total: number;
        approved: number;
        pending: number;
        rejected: number;
        lastDonationAt: Date | null;
    }>();
    for (const donation of donations) {
        const stats = statsByDonor.get(donation.donorId) ?? {
            total: 0, approved: 0, pending: 0, rejected: 0, lastDonationAt: null
        };
        stats.total += 1;
        if (donation.status === DonationStatus.PENDING) stats.pending += 1;
        else if (donation.status === DonationStatus.REJECTED) stats.rejected += 1;
        else if (donation.status !== DonationStatus.CANCELLED) stats.approved += 1;
        stats.lastDonationAt = latest(stats.lastDonationAt, donation.createdAt);
        statsByDonor.set(donation.donorId, stats);
    }

    return donors
        .map((donor) => {
            const stats = statsByDonor.get(donor.id);
            const lastDonationAt = stats?.lastDonationAt ?? null;
            return {
                id: donor.id,
                customUserId: donor.customUserId,
                email: donor.email,
                joinedAt: donor.createdAt.toISOString(),
                totalDonations: stats?.total ?? 0,
                approvedDonations: stats?.approved ?? 0,
                pendingDonations: stats?.pending ?? 0,
                rejectedDonations: stats?.rejected ?? 0,
                lastDonationAt: lastDonationAt?.toISOString() ?? null,
                status: toActivityStatus(lastDonationAt)
            };
        })
        .sort((a, b) => b.totalDonations - a.totalDonations);
};

export const getRecipientSummaries = async () => {
    const [recipients, requests] = await Promise.all([
        prisma.recipient.findMany({
            select: {
                customUserId: true,
                firstName: true,
                lastName: true,
                phoneNumber: true,
                city: true,
                district: true,
                createdAt: true,
                user: { select: { email: true } }
            }
        }),
        prisma.foodRequest.findMany({
            select: { recipientId: true, status: true, createdAt: true }
        })
    ]);

    const statsByRecipient = new Map<string, {
        total: number;
        approved: number;
        pending: number;
        rejected: number;
        lastRequestAt: Date | null;
    }>();
    for (const request of requests) {
        const stats = statsByRecipient.get(request.recipientId) ?? {
            total: 0, approved: 0, pending: 0, rejected: 0, lastRequestAt: null
        };
        stats.total += 1;
        if (request.status === 'APPROVED') stats.approved += 1;
        else if (request.status === 'REJECTED') stats.rejected += 1;
        else stats.pending += 1;
        stats.lastRequestAt = latest(stats.lastRequestAt, request.createdAt);
        statsByRecipient.set(request.recipientId, stats);
    }

    return recipients
        .map((recipient) => {
            const stats = statsByRecipient.get(recipient.customUserId);
            const lastRequestAt = stats?.lastRequestAt ?? null;
            return {
                customUserId: recipient.customUserId,
                name: `${recipient.firstName} ${recipient.lastName}`.trim(),
                email: recipient.user.email,
                phoneNumber: recipient.phoneNumber,
                location: [recipient.city, recipient.district].filter(Boolean).join(', '),
                joinedAt: recipient.createdAt.toISOString(),
                totalRequests: stats?.total ?? 0,
                approvedRequests: stats?.approved ?? 0,
                pendingRequests: stats?.pending ?? 0,
                rejectedRequests: stats?.rejected ?? 0,
                lastRequestAt: lastRequestAt?.toISOString() ?? null,
                status: toActivityStatus(lastRequestAt)
            };
        })
        .sort((a, b) => b.totalRequests - a.totalRequests);
};

/** Delivery problems reported by volunteers are the platform's real alerts. */
export const getAlerts = async () => {
    const problems = await prisma.deliveryProblem.findMany({
        orderBy: { createdAt: 'desc' },
        take: 100,
        include: {
            delivery: {
                select: {
                    foodItem: true,
                    status: true,
                    pickupAddress: true,
                    dropoffAddress: true
                }
            }
        }
    });

    const alerts = problems.map((problem) => ({
        id: problem.id,
        deliveryId: problem.deliveryId,
        volunteerId: problem.volunteerId,
        problemType: problem.problemType,
        description: problem.description,
        status: problem.status,
        foodItem: problem.delivery.foodItem,
        deliveryStatus: problem.delivery.status,
        pickupAddress: problem.delivery.pickupAddress,
        dropoffAddress: problem.delivery.dropoffAddress,
        createdAt: problem.createdAt.toISOString(),
        updatedAt: problem.updatedAt.toISOString()
    }));

    // Open problems first, then newest first.
    const rank = (status: string) => (status === DeliveryProblemStatus.RESOLVED ? 1 : 0);
    alerts.sort((a, b) =>
        rank(a.status) - rank(b.status) ||
        b.createdAt.localeCompare(a.createdAt)
    );

    return {
        counts: {
            reported: alerts.filter((a) => a.status === DeliveryProblemStatus.REPORTED).length,
            acknowledged: alerts.filter((a) => a.status === DeliveryProblemStatus.ACKNOWLEDGED).length,
            resolved: alerts.filter((a) => a.status === DeliveryProblemStatus.RESOLVED).length
        },
        alerts
    };
};

export const updateAlertStatus = async (id: string, status: unknown) => {
    if (!OBJECT_ID_PATTERN.test(id)) {
        throw new AdminValidationError('Invalid alert id');
    }
    if (
        status !== DeliveryProblemStatus.ACKNOWLEDGED &&
        status !== DeliveryProblemStatus.RESOLVED
    ) {
        throw new AdminValidationError('Status must be ACKNOWLEDGED or RESOLVED');
    }

    const existing = await prisma.deliveryProblem.findUnique({ where: { id } });
    if (!existing) {
        throw new AdminValidationError('Alert not found', 404);
    }
    if (existing.status === DeliveryProblemStatus.RESOLVED) {
        throw new AdminValidationError('This alert is already resolved');
    }

    return prisma.deliveryProblem.update({ where: { id }, data: { status } });
};
