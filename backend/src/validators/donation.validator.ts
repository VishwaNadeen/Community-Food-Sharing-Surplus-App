export interface DonationInput {
    category?: string;
    quantity?: number;
    quantityUnit?: string;
    description?: string;
    expiryDate?: string;
    pickupLocation?: string;
    pickupDateTime?: string;
}

export const validateDonationInput = (data: DonationInput): string[] => {
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
        !quantityUnit ||
        !description ||
        !expiryDate ||
        !pickupLocation ||
        !pickupDateTime
    ) {
        errors.push("All donation fields are required.");
    }

    if (quantity !== undefined && (typeof quantity !== "number" || quantity <= 0)) {
        errors.push("Quantity must be greater than 0.");
    }

    const validQuantityUnits = [
        "KG",
        "G",
        "LITRE",
        "ML",
        "PACKETS",
        "BOXES",
        "PIECES"
    ];

    if (quantityUnit && !validQuantityUnits.includes(quantityUnit.toUpperCase())) {
        errors.push("Invalid quantity unit selected.");
    }

    if (description && description.trim().length < 5) {
        errors.push("Description must be at least 5 characters long.");
    }

    if (expiryDate) {
        const expiry = new Date(expiryDate);

        if (isNaN(expiry.getTime())) {
            errors.push("Invalid expiry date.");
        } else if (expiry <= new Date()) {
            errors.push("Expiry date must be in the future.");
        }
    }

    if (pickupDateTime) {
        const pickup = new Date(pickupDateTime);

        if (isNaN(pickup.getTime())) {
            errors.push("Invalid pickup date and time.");
        } else if (pickup <= new Date()) {
            errors.push("Pickup date and time must be in the future.");
        }
    }

    return errors;
};