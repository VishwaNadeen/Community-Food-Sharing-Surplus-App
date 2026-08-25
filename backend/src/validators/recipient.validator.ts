export interface RecipientProfileInput {
    firstName?: string;
    lastName?: string;
    phoneNumber?: string;
    addressLine1?: string;
    addressLine2?: string;
    city?: string;
    district?: string;
    latitude?: number;
    longitude?: number;
    timeZone?: string;
    language?: string;
}


// ====================== CREATE PROFILE VALIDATION ======================

export const validateRecipientProfileInput = (
    data: RecipientProfileInput
): string[] => {

    const errors: string[] = [];

    if (!data.firstName?.trim()) {
        errors.push('First name is required');
    }

    if (!data.lastName?.trim()) {
        errors.push('Last name is required');
    }

    if (!data.phoneNumber?.trim()) {
        errors.push('Phone number is required');
    }

    if (!data.addressLine1?.trim()) {
        errors.push('Address Line 1 is required');
    }

    if (!data.city?.trim()) {
        errors.push('City is required');
    }

    if (!data.district?.trim()) {
        errors.push('District is required');
    }

    if (!data.timeZone?.trim()) {
        errors.push('Time zone is required');
    }

    if (!data.language?.trim()) {
        errors.push('Language is required');
    }

    if (
        data.latitude !== undefined &&
        typeof data.latitude !== 'number'
    ) {
        errors.push('Latitude must be a number');
    }

    if (
        data.longitude !== undefined &&
        typeof data.longitude !== 'number'
    ) {
        errors.push('Longitude must be a number');
    }

    return errors;
};


// ====================== UPDATE PROFILE VALIDATION ======================

export const validateRecipientProfileUpdate = (
    data: RecipientProfileInput
): string[] => {

    const errors: string[] = [];

    if (
        data.firstName !== undefined &&
        !data.firstName.trim()
    ) {
        errors.push('First name cannot be empty');
    }

    if (
        data.lastName !== undefined &&
        !data.lastName.trim()
    ) {
        errors.push('Last name cannot be empty');
    }

    if (
        data.phoneNumber !== undefined &&
        !data.phoneNumber.trim()
    ) {
        errors.push('Phone number cannot be empty');
    }

    if (
        data.addressLine1 !== undefined &&
        !data.addressLine1.trim()
    ) {
        errors.push('Address Line 1 cannot be empty');
    }

    if (
        data.city !== undefined &&
        !data.city.trim()
    ) {
        errors.push('City cannot be empty');
    }

    if (
        data.district !== undefined &&
        !data.district.trim()
    ) {
        errors.push('District cannot be empty');
    }

    if (
        data.timeZone !== undefined &&
        !data.timeZone.trim()
    ) {
        errors.push('Time zone cannot be empty');
    }

    if (
        data.language !== undefined &&
        !data.language.trim()
    ) {
        errors.push('Language cannot be empty');
    }

    if (
        data.latitude !== undefined &&
        typeof data.latitude !== 'number'
    ) {
        errors.push('Latitude must be a number');
    }

    if (
        data.longitude !== undefined &&
        typeof data.longitude !== 'number'
    ) {
        errors.push('Longitude must be a number');
    }

    return errors;
};