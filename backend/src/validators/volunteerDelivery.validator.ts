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
};


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
        typeof data.latitude !== 'number'
    ) {
        errors.push(
            'Valid latitude is required.'
        );
    }

    if (
        typeof data.longitude !== 'number'
    ) {
        errors.push(
            'Valid longitude is required.'
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