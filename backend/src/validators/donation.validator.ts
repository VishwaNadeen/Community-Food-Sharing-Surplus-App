export interface RejectDonationInput {
    rejectionReason?: string;
}

export interface CreateDonationInput {
    title?: string;
    description?: string;
    foodType?: string;
    quantity?: string;
    unit?: string;
    expiryDate?: string | Date;
    pickupAddress?: string;
    contactNumber?: string;
}

export const validateRejectDonationInput = (data: RejectDonationInput): string[] => {
    const { rejectionReason } = data;
    const errors: string[] = [];

    if (!rejectionReason || typeof rejectionReason !== 'string' || rejectionReason.trim().length === 0) {
        errors.push('Rejection reason is required.');
    } else if (rejectionReason.trim().length < 3) {
        errors.push('Rejection reason must be at least 3 characters long.');
    }

    return errors;
};

export const validateCreateDonationInput = (data: CreateDonationInput): string[] => {
    const { title, quantity } = data;
    const errors: string[] = [];

    if (!title || typeof title !== 'string' || title.trim().length === 0) {
        errors.push('Food title is required.');
    }

    if (!quantity || typeof quantity !== 'string' || quantity.trim().length === 0) {
        errors.push('Quantity is required.');
    }

    return errors;
};
