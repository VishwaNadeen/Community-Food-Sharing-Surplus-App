export interface RejectFoodRequestInput {
    rejectionReason?: string;
}

export interface CreateFoodRequestInput {
    foodItem?: string;
    quantityRequested?: string;
    recipientName?: string;
    recipientContact?: string;
    deliveryAddress?: string;
    donationId?: string;
    notes?: string;
}

export const validateRejectFoodRequestInput = (data: RejectFoodRequestInput): string[] => {
    const { rejectionReason } = data;
    const errors: string[] = [];

    if (!rejectionReason || typeof rejectionReason !== 'string' || rejectionReason.trim().length === 0) {
        errors.push('Rejection reason is required.');
    } else if (rejectionReason.trim().length < 3) {
        errors.push('Rejection reason must be at least 3 characters long.');
    }

    return errors;
};

export const validateCreateFoodRequestInput = (data: CreateFoodRequestInput): string[] => {
    const { foodItem, quantityRequested } = data;
    const errors: string[] = [];

    if (!foodItem || typeof foodItem !== 'string' || foodItem.trim().length === 0) {
        errors.push('Requested food item is required.');
    }

    if (!quantityRequested || typeof quantityRequested !== 'string' || quantityRequested.trim().length === 0) {
        errors.push('Quantity requested is required.');
    }

    return errors;
};
