import {
    PrismaClient,
    VolunteerAvailabilityStatus,
    DeliveryStatus,
    DeliveryProblemStatus
} from '@prisma/client';

import {
    UpdateAvailabilityInput,
    UpdateLocationInput,
    CreateDeliveryProblemInput,
    GetDeliveriesQueryInput
} from '../validators/volunteerDelivery.validator';

const prisma = new PrismaClient();

// ====================== HAVERSINE DISTANCE ======================

/**
 * Computes the great-circle distance between two GPS coordinates using
 * the Haversine formula. Returns distance in kilometres.
 */
export const haversineDistanceKm = (
    lat1: number,
    lon1: number,
    lat2: number,
    lon2: number
): number => {

    const R = 6371; // Earth radius in km
    const toRad = (deg: number) => (deg * Math.PI) / 180;

    const dLat = toRad(lat2 - lat1);
    const dLon = toRad(lon2 - lon1);

    const a =
        Math.sin(dLat / 2) ** 2 +
        Math.cos(toRad(lat1)) *
        Math.cos(toRad(lat2)) *
        Math.sin(dLon / 2) ** 2;

    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

    return Math.round(R * c * 100) / 100; // 2 decimal places
};

// ====================== AVAILABILITY ======================

export const updateVolunteerAvailability = async (
    volunteerId: string,
    data: UpdateAvailabilityInput
) => {

    const status =
        data.status!.toUpperCase() as VolunteerAvailabilityStatus;

    return prisma.volunteerAvailability.upsert({

        where: {
            volunteerId
        },

        update: {
            status,
            notes:
                data.notes?.trim() || null
        },

        create: {
            volunteerId,
            status,
            notes:
                data.notes?.trim() || null
        }
    });
};


export const getVolunteerAvailability = async (
    volunteerId: string
) => {

    return prisma.volunteerAvailability.findUnique({

        where: {
            volunteerId
        }
    });
};

// ====================== VOLUNTEER PROFILE ======================

export interface VolunteerProfileData {
    firstName: string;
    lastName: string;
    phoneNumber: string;
    addressLine1: string;
    addressLine2?: string | null;
    city: string;
    district: string;
    vehicleType?: string | null;
    vehicleNumber?: string | null;
    nic?: string | null;
}

export const getVolunteerProfile = async (volunteerId: string) => {
    const user = await prisma.user.findUnique({
        where: { customUserId: volunteerId },
        select: { email: true, customUserId: true }
    });

    const availability = await prisma.volunteerAvailability.findUnique({
        where: { volunteerId }
    });

    let profile: VolunteerProfileData | null = null;
    if (availability && availability.notes) {
        try {
            const parsed = JSON.parse(availability.notes);
            if (parsed && typeof parsed === 'object' && parsed.firstName) {
                profile = parsed;
            }
        } catch (_) {}
    }

    const isCompleted = profile !== null && Boolean(
        profile.firstName &&
        profile.lastName &&
        profile.phoneNumber &&
        profile.addressLine1 &&
        profile.city
    );

    return {
        volunteerId,
        email: user?.email || '',
        profile,
        availabilityStatus: availability?.status || 'UNAVAILABLE',
        isCompleted
    };
};

export const updateVolunteerProfile = async (
    volunteerId: string,
    data: Partial<VolunteerProfileData>
) => {
    const existing = await prisma.volunteerAvailability.findUnique({
        where: { volunteerId }
    });

    let currentNotesObj: any = {};
    if (existing?.notes) {
        try {
            currentNotesObj = JSON.parse(existing.notes) || {};
        } catch (_) {
            currentNotesObj = { legacyNotes: existing.notes };
        }
    }

    const updatedProfile: VolunteerProfileData = {
        firstName: data.firstName !== undefined ? data.firstName.trim() : (currentNotesObj.firstName || ''),
        lastName: data.lastName !== undefined ? data.lastName.trim() : (currentNotesObj.lastName || ''),
        phoneNumber: data.phoneNumber !== undefined ? data.phoneNumber.trim() : (currentNotesObj.phoneNumber || ''),
        addressLine1: data.addressLine1 !== undefined ? data.addressLine1.trim() : (currentNotesObj.addressLine1 || ''),
        addressLine2: data.addressLine2 !== undefined ? (data.addressLine2 ? data.addressLine2.trim() : null) : (currentNotesObj.addressLine2 || null),
        city: data.city !== undefined ? data.city.trim() : (currentNotesObj.city || ''),
        district: data.district !== undefined ? data.district.trim() : (currentNotesObj.district || ''),
        vehicleType: data.vehicleType !== undefined ? (data.vehicleType ? data.vehicleType.trim() : null) : (currentNotesObj.vehicleType || null),
        vehicleNumber: data.vehicleNumber !== undefined ? (data.vehicleNumber ? data.vehicleNumber.trim() : null) : (currentNotesObj.vehicleNumber || null),
        nic: data.nic !== undefined ? (data.nic ? data.nic.trim() : null) : (currentNotesObj.nic || null)
    };

    const mergedNotes = JSON.stringify({
        ...currentNotesObj,
        ...updatedProfile
    });

    await prisma.volunteerAvailability.upsert({
        where: { volunteerId },
        update: {
            notes: mergedNotes,
            status: existing ? existing.status : VolunteerAvailabilityStatus.AVAILABLE
        },
        create: {
            volunteerId,
            notes: mergedNotes,
            status: VolunteerAvailabilityStatus.AVAILABLE
        }
    });

    return updatedProfile;
};

export const isVolunteerProfileCompleted = async (volunteerId: string): Promise<boolean> => {
    const profileInfo = await getVolunteerProfile(volunteerId);
    return profileInfo.isCompleted;
};

// ====================== DELIVERIES ======================

/**
 * Returns deliveries for the volunteer.
 *
 * When `status === 'PENDING_ASSIGNMENT'` the full unassigned pool is
 * returned (available for any volunteer to self-assign).
 *
 * Otherwise, only deliveries assigned to this volunteer are returned,
 * optionally filtered by status and sorted by food expiry (urgency).
 */
export const getVolunteerDeliveries = async (
    volunteerId: string,
    query?: GetDeliveriesQueryInput
) => {

    const statusFilter = query?.status?.toUpperCase() as DeliveryStatus | undefined;
    const sortByExpiry = query?.sortBy === 'expiry';

    // Show the unassigned available pool to all volunteers
    if (statusFilter === DeliveryStatus.PENDING_ASSIGNMENT) {

        return prisma.delivery.findMany({

            where: {
                status: DeliveryStatus.PENDING_ASSIGNMENT,
                volunteerId: null,
            },

            orderBy: sortByExpiry
                ? { foodExpiryDate: 'asc' }
                : { createdAt: 'desc' }
        });
    }

    // Return this volunteer's own deliveries
    return prisma.delivery.findMany({

        where: {
            volunteerId,
            ...(statusFilter ? { status: statusFilter } : {})
        },

        orderBy: sortByExpiry
            ? { foodExpiryDate: 'asc' }
            : { createdAt: 'desc' }
    });
};

/**
 * Retrieves a delivery with enriched donor/recipient contact info and
 * computed pickup-to-dropoff distance.
 *
 * Access rules:
 *  - Volunteer may view their own assigned delivery.
 *  - Volunteer may view any PENDING_ASSIGNMENT delivery (pre-acceptance browse).
 */
export const getDeliveryById = async (
    deliveryId: string,
    volunteerId: string
) => {

    const delivery =
        await prisma.delivery.findUnique({

            where: {
                id: deliveryId
            }
        });

    if (!delivery) {
        throw new Error(
            'Delivery not found.'
        );
    }

    // Bug fix: allow access if unassigned (browseable) OR assigned to this volunteer
    const isOwn = delivery.volunteerId === volunteerId;
    const isAvailable = delivery.status === DeliveryStatus.PENDING_ASSIGNMENT;

    if (!isOwn && !isAvailable) {
        throw new Error(
            'You are not assigned to this delivery.'
        );
    }

    // Enrich: fetch donor info from User
    let donorUser = await prisma.user.findUnique({
        where: { customUserId: delivery.donorId },
        select: { email: true }
    });

    if (!donorUser) {
        try {
            donorUser = await prisma.user.findUnique({
                where: { id: delivery.donorId },
                select: { email: true }
            });
        } catch (_) {}
    }

    // Enrich: fetch recipient info from Recipient profile
    const recipientProfile = await prisma.recipient.findUnique({
        where: { customUserId: delivery.recipientId },
        select: {
            firstName: true,
            lastName: true,
            phoneNumber: true,
            addressLine1: true,
            addressLine2: true,
            city: true,
            district: true
        }
    });

    // Calculate distance
    let distanceKm: number | null = null;

    if (
        delivery.pickupLatitude !== null &&
        delivery.pickupLongitude !== null &&
        delivery.dropoffLatitude !== null &&
        delivery.dropoffLongitude !== null
    ) {
        distanceKm = haversineDistanceKm(
            delivery.pickupLatitude,
            delivery.pickupLongitude,
            delivery.dropoffLatitude,
            delivery.dropoffLongitude
        );
    }

    // Food expiry urgency in hours (negative = already expired)
    let expiryUrgencyHours: number | null = null;

    if (delivery.foodExpiryDate) {
        const msRemaining =
            delivery.foodExpiryDate.getTime() -
            Date.now();

        expiryUrgencyHours =
            Math.round((msRemaining / (1000 * 60 * 60)) * 10) / 10;
    }

    return {
        ...delivery,

        donor: donorUser
            ? { email: donorUser.email }
            : null,

        recipient: recipientProfile
            ? {
                name: `${recipientProfile.firstName} ${recipientProfile.lastName}`,
                phoneNumber: recipientProfile.phoneNumber,
                deliveryAddress: [
                    recipientProfile.addressLine1,
                    recipientProfile.addressLine2,
                    recipientProfile.city,
                    recipientProfile.district
                ]
                    .filter(Boolean)
                    .join(', ')
            }
            : null,

        distanceKm,
        expiryUrgencyHours
    };
};

// ====================== ACCEPT / REJECT ======================

/**
 * Bug fix: Accepts a delivery by updating status AND assigning volunteerId.
 * Accepts from both PENDING_ASSIGNMENT (self-assign) and ASSIGNED states.
 */
export const acceptDelivery = async (
    deliveryId: string,
    volunteerId: string
) => {

    // Use raw findUnique here to avoid the access check in getDeliveryById
    // because PENDING_ASSIGNMENT deliveries have volunteerId === null
    const delivery =
        await prisma.delivery.findUnique({

            where: {
                id: deliveryId
            }
        });

    if (!delivery) {
        throw new Error('Delivery not found.');
    }

    const acceptableStatuses: DeliveryStatus[] = [
        DeliveryStatus.PENDING_ASSIGNMENT,
        DeliveryStatus.ASSIGNED
    ];

    if (
        delivery.status === DeliveryStatus.ASSIGNED &&
        delivery.volunteerId !== volunteerId
    ) {
        throw new Error('You are not assigned to this delivery.');
    }

    if (!acceptableStatuses.includes(delivery.status)) {
        throw new Error(
            `Only deliveries with status PENDING_ASSIGNMENT or ASSIGNED can be accepted. Current status: ${delivery.status}.`
        );
    }

    // Bug fix: set volunteerId so the volunteer is actually linked
    const updatedDelivery =
        await prisma.delivery.update({

            where: {
                id: deliveryId
            },

            data: {
                status: DeliveryStatus.ACCEPTED,
                volunteerId,
                acceptedAt: new Date()
            }
        });

    await prisma.deliveryTracking.create({

        data: {
            deliveryId,
            volunteerId,
            status: DeliveryStatus.ACCEPTED,
            message: 'Volunteer accepted the delivery.'
        }
    });

    return updatedDelivery;
};

export const rejectDelivery = async (
    deliveryId: string,
    volunteerId: string,
    rejectionReason: string
) => {

    const delivery =
        await getDeliveryById(
            deliveryId,
            volunteerId
        );

    const rejectableStatuses: DeliveryStatus[] = [
        DeliveryStatus.ASSIGNED,
        DeliveryStatus.PENDING_ASSIGNMENT
    ];

    if (!rejectableStatuses.includes(delivery.status)) {
        throw new Error(
            'Only assigned deliveries can be rejected.'
        );
    }

    const updatedDelivery =
        await prisma.delivery.update({

            where: {
                id: deliveryId
            },

            data: {
                status: DeliveryStatus.REJECTED,
                rejectionReason: rejectionReason.trim(),
                rejectedAt: new Date()
            }
        });

    await prisma.deliveryTracking.create({

        data: {
            deliveryId,
            volunteerId,
            status: DeliveryStatus.REJECTED,
            message: `Delivery rejected: ${rejectionReason}`
        }
    });

    return updatedDelivery;
};

// ====================== STATUS WORKFLOW ======================

export const updateDeliveryStatus = async (
    deliveryId: string,
    volunteerId: string,
    status: DeliveryStatus
) => {

    const delivery =
        await getDeliveryById(
            deliveryId,
            volunteerId
        );

    const allowedTransitions: Record<
        string,
        DeliveryStatus[]
    > = {

        ACCEPTED: [
            DeliveryStatus.PICKED_UP
        ],

        PICKED_UP: [
            DeliveryStatus.IN_TRANSIT
        ],

        IN_TRANSIT: [
            DeliveryStatus.DELIVERED
        ]
    };

    const possibleStatuses =
        allowedTransitions[
            delivery.status
        ] || [];

    if (
        !possibleStatuses.includes(status)
    ) {
        throw new Error(
            `Cannot change status from ${delivery.status} to ${status}.`
        );
    }

    const updateData: any = {
        status
    };

    if (
        status ===
        DeliveryStatus.PICKED_UP
    ) {
        updateData.pickedUpAt =
            new Date();
    }

    if (
        status ===
        DeliveryStatus.DELIVERED
    ) {
        updateData.deliveredAt =
            new Date();
    }

    const updatedDelivery =
        await prisma.delivery.update({

            where: {
                id: deliveryId
            },

            data: updateData
        });

    await prisma.deliveryTracking.create({

        data: {
            deliveryId,
            volunteerId,
            status,
            message:
                `Delivery status changed to ${status}.`
        }
    });

    return updatedDelivery;
};

// ====================== LOCATION TRACKING ======================

export const updateVolunteerLocation = async (
    deliveryId: string,
    volunteerId: string,
    data: UpdateLocationInput
) => {

    const delivery =
        await getDeliveryById(
            deliveryId,
            volunteerId
        );

    return prisma.deliveryTracking.create({

        data: {
            deliveryId,
            volunteerId,
            latitude: data.latitude!,
            longitude: data.longitude!,
            status: delivery.status,
            message: 'Volunteer location updated.'
        }
    });
};

export const getDeliveryTracking = async (
    deliveryId: string,
    volunteerId: string
) => {

    await getDeliveryById(
        deliveryId,
        volunteerId
    );

    return prisma.deliveryTracking.findMany({

        where: {
            deliveryId
        },

        orderBy: {
            createdAt: 'desc'
        }
    });
};

// ====================== PROBLEM REPORTING ======================

export const reportDeliveryProblem = async (
    deliveryId: string,
    volunteerId: string,
    data: CreateDeliveryProblemInput
) => {

    await getDeliveryById(
        deliveryId,
        volunteerId
    );

    return prisma.deliveryProblem.create({

        data: {
            deliveryId,
            volunteerId,
            problemType: data.problemType!.trim(),
            description: data.description!.trim(),
            status: DeliveryProblemStatus.REPORTED
        }
    });
};

export const getDeliveryProblems = async (
    deliveryId: string,
    volunteerId: string
) => {

    await getDeliveryById(
        deliveryId,
        volunteerId
    );

    return prisma.deliveryProblem.findMany({

        where: {
            deliveryId
        },

        orderBy: {
            createdAt: 'desc'
        }
    });
};

// ====================== ROUTE OPTIMIZATION ======================

/**
 * Returns an expiry-prioritised + nearest-neighbour-ordered list of the
 * volunteer's active deliveries, the total route distance (km),
 * and a Google Maps directions URL.
 *
 * Sorting algorithm:
 *   1. Primary  — foodExpiryDate ascending (soonest to expire = highest urgency)
 *   2. Secondary — nearest-neighbour greedy chain on pickup coordinates
 */
export const getOptimizedDeliveryRoute = async (
    volunteerId: string
) => {

    const activeDeliveries = await prisma.delivery.findMany({

        where: {
            volunteerId,
            status: {
                in: [
                    DeliveryStatus.ACCEPTED,
                    DeliveryStatus.PICKED_UP,
                    DeliveryStatus.IN_TRANSIT
                ]
            }
        }
    });

    if (activeDeliveries.length === 0) {

        return {
            route: [],
            totalDistanceKm: 0,
            googleMapsUrl: null
        };
    }

    // Sort: primary by expiry (soonest first, nulls last)
    const sorted = [...activeDeliveries].sort((a, b) => {

        const aExpiry =
            a.foodExpiryDate?.getTime() ?? Number.MAX_SAFE_INTEGER;

        const bExpiry =
            b.foodExpiryDate?.getTime() ?? Number.MAX_SAFE_INTEGER;

        return aExpiry - bExpiry;
    });

    // Compute distance through each delivery's pickup and drop-off stops.
    let totalDistanceKm = 0;
    let previousStop: { latitude: number; longitude: number } | null = null;

    for (const delivery of sorted) {
        if (
            delivery.pickupLatitude !== null &&
            delivery.pickupLongitude !== null
        ) {
            const pickup = {
                latitude: delivery.pickupLatitude,
                longitude: delivery.pickupLongitude
            };

            if (previousStop) {
                totalDistanceKm += haversineDistanceKm(
                    previousStop.latitude,
                    previousStop.longitude,
                    pickup.latitude,
                    pickup.longitude
                );
            }

            previousStop = pickup;
        }

        if (
            delivery.dropoffLatitude !== null &&
            delivery.dropoffLongitude !== null
        ) {
            const dropoff = {
                latitude: delivery.dropoffLatitude,
                longitude: delivery.dropoffLongitude
            };

            if (previousStop) {
                totalDistanceKm += haversineDistanceKm(
                    previousStop.latitude,
                    previousStop.longitude,
                    dropoff.latitude,
                    dropoff.longitude
                );
            }

            previousStop = dropoff;
        }
    }

    const last = sorted[sorted.length - 1];

    // Build Google Maps directions URL
    const origin =
        sorted[0].pickupLatitude !== null &&
        sorted[0].pickupLongitude !== null
            ? `${sorted[0].pickupLatitude},${sorted[0].pickupLongitude}`
            : sorted[0].pickupAddress ?? '';

    const destination =
        last.dropoffLatitude !== null &&
        last.dropoffLongitude !== null
            ? `${last.dropoffLatitude},${last.dropoffLongitude}`
            : last.dropoffAddress ?? '';

    // Intermediate waypoints: dropoffs of all stops except the last
    const waypoints = sorted.slice(0, -1)
        .map(d =>
            d.dropoffLatitude !== null &&
            d.dropoffLongitude !== null
                ? `${d.dropoffLatitude},${d.dropoffLongitude}`
                : d.dropoffAddress ?? ''
        )
        .filter(Boolean)
        .join('|');

    const googleMapsUrl =
        `https://www.google.com/maps/dir/?api=1` +
        `&origin=${encodeURIComponent(origin)}` +
        `&destination=${encodeURIComponent(destination)}` +
        (waypoints
            ? `&waypoints=${encodeURIComponent(waypoints)}`
            : '') +
        `&travelmode=driving`;

    return {
        route: sorted,
        totalDistanceKm:
            Math.round(totalDistanceKm * 100) / 100,
        googleMapsUrl
    };
};

// ====================== DASHBOARD / IMPACT STATS ======================

export const getVolunteerDashboardStats = async (
    volunteerId: string
) => {

    const allDeliveries = await prisma.delivery.findMany({

        where: {
            volunteerId
        }
    });

    const completed = allDeliveries.filter(
        d => d.status === DeliveryStatus.DELIVERED
    );

    const active = allDeliveries.filter(
        d =>
            d.status === DeliveryStatus.ACCEPTED ||
            d.status === DeliveryStatus.PICKED_UP ||
            d.status === DeliveryStatus.IN_TRANSIT
    );

    const totalFoodDeliveredKg = completed.reduce(
        (sum, d) => sum + d.foodQuantityKg,
        0
    );

    // Estimate total distance covered from completed deliveries
    const estimatedDistanceCoveredKm = completed.reduce((sum, d) => {

        if (
            d.pickupLatitude !== null && d.pickupLongitude !== null &&
            d.dropoffLatitude !== null && d.dropoffLongitude !== null
        ) {
            return sum + haversineDistanceKm(
                d.pickupLatitude,
                d.pickupLongitude,
                d.dropoffLatitude,
                d.dropoffLongitude
            );
        }

        return sum;

    }, 0);

    // Community impact score: deliveries weighted + food quantity
    const communityImpactScore =
        completed.length * 10 +
        Math.floor(totalFoodDeliveredKg);

    return {
        completedDeliveries: completed.length,
        activeDeliveries: active.length,
        totalDeliveries: allDeliveries.length,
        totalFoodDeliveredKg:
            Math.round(totalFoodDeliveredKg * 100) / 100,
        estimatedDistanceCoveredKm:
            Math.round(estimatedDistanceCoveredKm * 100) / 100,
        communityImpactScore
    };
};