import { DeliveryStatus, PrismaClient } from '@prisma/client';

import {
    getVolunteerProfile,
    haversineDistanceKm
} from './volunteerDelivery.service';

const prisma = new PrismaClient();

// Delivery statuses a donor can see on the My Delivery page: from the
// moment a volunteer accepts the delivery until it is delivered, so the
// donor can follow every step.
const DONOR_VISIBLE_STATUSES: DeliveryStatus[] = [
    DeliveryStatus.ACCEPTED,
    DeliveryStatus.PICKED_UP,
    DeliveryStatus.IN_TRANSIT,
    DeliveryStatus.DELIVERED
];

// ====================== GET DONOR DELIVERIES ======================

/**
 * Returns the logged-in donor's deliveries that a volunteer has accepted
 * (including ones picked up, in transit or delivered), with the
 * volunteer's contact details, the food details and a short recipient
 * summary.
 */
export const getDonorDeliveries = async (donorCustomUserId: string) => {

    const user = await prisma.user.findUnique({
        where: { customUserId: donorCustomUserId },
        select: { id: true }
    });

    if (!user) {
        throw new Error('Donor not found');
    }

    // Delivery.donorId stores the donor's User id (the same value as
    // FoodDonation.donorId). Older records may use the customUserId.
    const deliveries = await prisma.delivery.findMany({
        where: {
            donorId: { in: [user.id, donorCustomUserId] },
            status: { in: DONOR_VISIBLE_STATUSES }
        },
        orderBy: { acceptedAt: 'desc' }
    });

    return Promise.all(
        deliveries.map(async (delivery) => {

            const volunteerInfo = delivery.volunteerId
                ? await getVolunteerProfile(delivery.volunteerId)
                : null;

            const recipient = await prisma.recipient.findUnique({
                where: { customUserId: delivery.recipientId },
                select: {
                    firstName: true,
                    lastName: true,
                    city: true,
                    district: true
                }
            });

            const hasRoute =
                delivery.pickupLatitude !== null &&
                delivery.pickupLongitude !== null &&
                delivery.dropoffLatitude !== null &&
                delivery.dropoffLongitude !== null;

            const distanceKm = hasRoute
                ? Number(
                    haversineDistanceKm(
                        delivery.pickupLatitude!,
                        delivery.pickupLongitude!,
                        delivery.dropoffLatitude!,
                        delivery.dropoffLongitude!
                    ).toFixed(2)
                )
                : null;

            return {
                id: delivery.id,
                status: delivery.status,
                acceptedAt: delivery.acceptedAt,
                pickedUpAt: delivery.pickedUpAt,
                deliveredAt: delivery.deliveredAt,
                createdAt: delivery.createdAt,
                updatedAt: delivery.updatedAt,

                food: {
                    item: delivery.foodItem,
                    quantityKg: delivery.foodQuantityKg,
                    expiryDate: delivery.foodExpiryDate
                },

                pickup: {
                    address: delivery.pickupAddress,
                    latitude: delivery.pickupLatitude,
                    longitude: delivery.pickupLongitude
                },

                dropoff: {
                    address: delivery.dropoffAddress,
                    latitude: delivery.dropoffLatitude,
                    longitude: delivery.dropoffLongitude
                },

                distanceKm,

                // Only contact details the donor needs to hand over the
                // food. NIC and home address are not shared.
                volunteer: volunteerInfo
                    ? {
                        volunteerId: volunteerInfo.volunteerId,
                        firstName: volunteerInfo.profile?.firstName ?? null,
                        lastName: volunteerInfo.profile?.lastName ?? null,
                        phoneNumber: volunteerInfo.profile?.phoneNumber ?? null,
                        email: volunteerInfo.email || null,
                        vehicleType: volunteerInfo.profile?.vehicleType ?? null,
                        vehicleNumber: volunteerInfo.profile?.vehicleNumber ?? null
                    }
                    : null,

                // Recipient summary only, without phone number or address.
                recipient: recipient
                    ? {
                        name: `${recipient.firstName} ${recipient.lastName}`.trim(),
                        city: recipient.city,
                        district: recipient.district
                    }
                    : null
            };
        })
    );
};
