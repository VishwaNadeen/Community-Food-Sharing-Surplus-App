export interface UpdateAvailabilityInput {
    status?: string;
    notes?: string;
}

export interface RejectDeliveryInput {
    rejectionReason?: string;
}

export interface UpdateDeliveryStatusInput {
    status?: string;
}

export interface UpdateLocationInput {
    latitude?: number;
    longitude?: number;
}

export interface CreateDeliveryProblemInput {
    problemType?: string;
    description?: string;
}

export interface GetDeliveriesQueryInput {
    status?: string;
    sortBy?: string;
}

const VALID_DELIVERY_STATUSES = [
    'PENDING_ASSIGNMENT',
    'ASSIGNED',
    'ACCEPTED',
    'PICKED_UP',
    'IN_TRANSIT',
    'DELIVERED',
    'REJECTED',
    'CANCELLED'
];


export const validateAvailability = (
    data: UpdateAvailabilityInput
): string[] => {

    const errors: string[] = [];

    const allowedStatuses = [
        'AVAILABLE',
        'UNAVAILABLE'
    ];

    if (!data.status) {
        errors.push(
            'Availability status is required.'
        );
    }

    if (
        data.status &&
        !allowedStatuses.includes(
            data.status.toUpperCase()
        )
    ) {
        errors.push(
            'Status must be AVAILABLE or UNAVAILABLE.'
        );
    }

    if (
        data.notes !== undefined &&
        typeof data.notes !== 'string'
    ) {
        errors.push(
            'Notes must be a string.'
        );
    }

    return errors;
};


export const validateRejectDelivery = (
    data: RejectDeliveryInput
): string[] => {

    const errors: string[] = [];

    if (
        !data.rejectionReason ||
        typeof data.rejectionReason !== 'string' ||
        data.rejectionReason.trim().length === 0
    ) {
        errors.push(
            'Rejection reason is required.'
        );
    }

    return errors;
};


export const validateDeliveryStatus = (
    data: UpdateDeliveryStatusInput
): string[] => {

    const errors: string[] = [];

    const allowedStatuses = [
        'PICKED_UP',
        'IN_TRANSIT',
        'DELIVERED'
    ];

    if (!data.status) {
        errors.push(
            'Delivery status is required.'
        );
    }

    if (
        data.status &&
        !allowedStatuses.includes(
            data.status.toUpperCase()
        )
    ) {
        errors.push(
            'Status must be PICKED_UP, IN_TRANSIT or DELIVERED.'
        );
    }

    return errors;
};


export const validateLocation = (
    data: UpdateLocationInput
): string[] => {

    const errors: string[] = [];

    if (
        typeof data.latitude !== 'number' ||
        isNaN(data.latitude) ||
        data.latitude < -90 ||
        data.latitude > 90
    ) {
        errors.push(
            'Valid latitude is required (number between -90 and 90).'
        );
    }

    if (
        typeof data.longitude !== 'number' ||
        isNaN(data.longitude) ||
        data.longitude < -180 ||
        data.longitude > 180
    ) {
        errors.push(
            'Valid longitude is required (number between -180 and 180).'
        );
    }

    return errors;
};


export const validateDeliveryProblem = (
    data: CreateDeliveryProblemInput
): string[] => {

    const errors: string[] = [];

    if (
        !data.problemType ||
        typeof data.problemType !== 'string' ||
        data.problemType.trim().length === 0
    ) {
        errors.push(
            'Problem type is required.'
        );
    }

    if (
        !data.description ||
        typeof data.description !== 'string' ||
        data.description.trim().length === 0
    ) {
        errors.push(
            'Problem description is required.'
        );
    }

    return errors;
};


export const validateGetDeliveriesQuery = (
    data: GetDeliveriesQueryInput
): string[] => {

    const errors: string[] = [];

    if (
        data.status &&
        !VALID_DELIVERY_STATUSES.includes(
            data.status.toUpperCase()
        )
    ) {
        errors.push(
            `Invalid status filter. Must be one of: ${VALID_DELIVERY_STATUSES.join(', ')}.`
        );
    }

    if (
        data.sortBy &&
        data.sortBy !== 'expiry'
    ) {
        errors.push(
            'sortBy must be "expiry" if provided.'
        );
    }

    return errors;
};