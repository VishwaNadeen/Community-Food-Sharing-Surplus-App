import { DonationStatus, PrismaClient, QuantityUnit } from '@prisma/client';
import { DonationInput } from '../validators/donation.validator';

const prisma = new PrismaClient();

export const createDonation = async (
    donorCustomUserId: string,
    donationData: DonationInput
) => {
    const donor = await prisma.user.findUnique({
        where: {
            customUserId: donorCustomUserId
        }
    });

    if (!donor) {
        throw new Error('Donor not found');
    }

    return prisma.foodDonation.create({
        data: {
            donorId: donor.id,
            category: donationData.category!.trim(),
            quantity: donationData.quantity!,
            quantityUnit: donationData.quantityUnit!.toUpperCase() as QuantityUnit,
            description: donationData.description!.trim(),
            expiryDate: new Date(donationData.expiryDate!),
            pickupLocation: donationData.pickupLocation!.trim(),
            pickupDateTime: new Date(donationData.pickupDateTime!),
            status: DonationStatus.AVAILABLE
        }
    });
};