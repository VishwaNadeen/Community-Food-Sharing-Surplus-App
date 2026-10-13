
export interface DonationInput {
    category?: string;
    quantity?: number;
    quantityUnit?: string;
    description?: string;
    expiryDate?: string;
    pickupLocation?: string;
    pickupDateTime?: string;
}

const isValidQuantity = (quantity: unknown): boolean => {
    return (
        typeof quantity === 'number' &&
        Number.isFinite(quantity) &&
        quantity > 0
    );
};

const validQuantityUnits = [
    'KG',
    'G',
    'LITRE',
    'ML',
    'PACKETS',
    'BOXES',
    'PIECES'
];

export const validateDonationInput = (
    data: DonationInput
): string[] => {
    const {
        category,
        quantity,
        quantityUnit,
        description,
        expiryDate,
        pickupLocation,
        pickupDateTime
    } = data;

    const errors: string[] = [];

    if (
        !category ||
        quantity === undefined ||
        quantity === null ||
        !quantityUnit ||
        !description ||
        !expiryDate ||
        !pickupLocation ||
        !pickupDateTime
    ) {
        errors.push('All donation fields are required.');
    }

    if (!isValidQuantity(quantity)) {
        errors.push('Quantity must be a valid number greater than 0.');
    }

    if (
        quantityUnit &&
        !validQuantityUnits.includes(quantityUnit.toUpperCase())
    ) {
        errors.push('Invalid quantity unit selected.');
    }

    if (description && description.trim().length < 5) {
        errors.push('Description must be at least 5 characters long.');
    }

    if (expiryDate) {
        const expiry = new Date(expiryDate);

        if (isNaN(expiry.getTime())) {
            errors.push('Invalid expiry date.');
        } else if (expiry <= new Date()) {
            errors.push('Expiry date must be in the future.');
        }
    }

    if (pickupDateTime) {
        const pickup = new Date(pickupDateTime);

        if (isNaN(pickup.getTime())) {
            errors.push('Invalid pickup date and time.');
        } else if (pickup <= new Date()) {
            errors.push('Pickup date and time must be in the future.');
        }
    }

    return errors;
};

export const validateDonationUpdateInput = (
    data: DonationInput
): string[] => {
    const {
        category,
        quantity,
        quantityUnit,
        description,
        expiryDate,
        pickupLocation,
        pickupDateTime
    } = data;

    const errors: string[] = [];

    if (
        category === undefined &&
        quantity === undefined &&
        quantityUnit === undefined &&
        description === undefined &&
        expiryDate === undefined &&
        pickupLocation === undefined &&
        pickupDateTime === undefined
    ) {
        errors.push('At least one donation field is required.');
        return errors;
    }

    if (quantity !== undefined && !isValidQuantity(quantity)) {
        errors.push('Quantity must be a valid number greater than 0.');
    }

    if (
        quantityUnit &&
        !validQuantityUnits.includes(quantityUnit.toUpperCase())
    ) {
        errors.push('Invalid quantity unit selected.');
    }

    if (
        description !== undefined &&
        description.trim().length < 5
    ) {
        errors.push('Description must be at least 5 characters long.');
    }

    if (expiryDate !== undefined) {
        const expiry = new Date(expiryDate);

        if (isNaN(expiry.getTime())) {
            errors.push('Invalid expiry date.');
        } else if (expiry <= new Date()) {
            errors.push('Expiry date must be in the future.');
        }
    }

    if (pickupDateTime !== undefined) {
        const pickup = new Date(pickupDateTime);

        if (isNaN(pickup.getTime())) {
            errors.push('Invalid pickup date and time.');
        } else if (pickup <= new Date()) {
            errors.push('Pickup date and time must be in the future.');
        }
    }

    return errors;
};

export interface RejectDonationInput {
    rejectionReason?: string;
}

export const validateRejectDonationInput = (
    data: RejectDonationInput
): string[] => {
    const { rejectionReason } = data;
    const errors: string[] = [];

    if (
        !rejectionReason ||
        typeof rejectionReason !== 'string' ||
        rejectionReason.trim().length === 0
    ) {
        errors.push('Rejection reason is required.');
    } else if (rejectionReason.trim().length < 3) {
        errors.push('Rejection reason must be at least 3 characters long.');
    }

    return errors;
};

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

export const validateCreateDonationInput = (
    data: CreateDonationInput
): string[] => {
    const { title, quantity } = data;
    const errors: string[] = [];

    if (
        !title ||
        typeof title !== 'string' ||
        title.trim().length === 0
    ) {
        errors.push('Food title is required.');
    }

    if (
        !quantity ||
        typeof quantity !== 'string' ||
        quantity.trim().length === 0
    ) {
        errors.push('Quantity is required.');
    }

    return errors;
};
