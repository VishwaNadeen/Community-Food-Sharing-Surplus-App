import {
    PrismaClient,
    VolunteerAvailabilityStatus,
    DeliveryStatus,
    DeliveryProblemStatus
} from '@prisma/client';

import {
    UpdateAvailabilityInput,
    UpdateLocationInput,
    CreateDeliveryProblemInput
} from '../validators/volunteerDelivery.validator';

const prisma = new PrismaClient();

export const updateVolunteerAvailability = async (
    volunteerId: string,
    data: UpdateAvailabilityInput
) => {

    const status =
        data.status!.toUpperCase()
        as VolunteerAvailabilityStatus;

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

export const getVolunteerDeliveries = async (
    volunteerId: string
) => {

    return prisma.delivery.findMany({

        where: {
            volunteerId
        },

        orderBy: {
            createdAt: 'desc'
        }
    });
};

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

    if (
        delivery.volunteerId !== volunteerId
    ) {
        throw new Error(
            'You are not assigned to this delivery.'
        );
    }

    return delivery;
};

export const acceptDelivery = async (
    deliveryId: string,
    volunteerId: string
) => {

    const delivery =
        await getDeliveryById(
            deliveryId,
            volunteerId
        );

    if (
        delivery.status !==
        DeliveryStatus.ASSIGNED
    ) {
        throw new Error(
            'Only assigned deliveries can be accepted.'
        );
    }

    const updatedDelivery =
        await prisma.delivery.update({

            where: {
                id: deliveryId
            },

            data: {
                status:
                    DeliveryStatus.ACCEPTED,

                acceptedAt:
                    new Date()
            }
        });

    await prisma.deliveryTracking.create({

        data: {
            deliveryId,
            volunteerId,

            status:
                DeliveryStatus.ACCEPTED,

            message:
                'Volunteer accepted the delivery.'
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

    if (
        delivery.status !==
        DeliveryStatus.ASSIGNED
    ) {
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

                status:
                    DeliveryStatus.REJECTED,

                rejectionReason:
                    rejectionReason.trim(),

                rejectedAt:
                    new Date()
            }
        });

    await prisma.deliveryTracking.create({

        data: {

            deliveryId,
            volunteerId,

            status:
                DeliveryStatus.REJECTED,

            message:
                `Delivery rejected: ${rejectionReason}`
        }
    });

    return updatedDelivery;
};

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

            latitude:
                data.latitude!,

            longitude:
                data.longitude!,

            status:
                delivery.status,

            message:
                'Volunteer location updated.'
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

            problemType:
                data.problemType!.trim(),

            description:
                data.description!.trim(),

            status:
                DeliveryProblemStatus.REPORTED
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