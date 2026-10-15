// ============================================================
// One-off backfill: copy each donor profile's latitude/longitude
// onto all of that donor's existing food donations.
//
// New and updated profiles are synced automatically by
// donor.service.ts. This script is only needed for data created
// before the FoodDonation.latitude / longitude fields existed.
//
// Run from the backend folder:  npm run sync:donation-locations
// ============================================================

import 'dotenv/config';
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

const main = async () => {
    const donors = await prisma.donor.findMany({
        select: {
            customUserId: true,
            latitude: true,
            longitude: true,
            user: { select: { id: true } }
        }
    });

    let updatedDonations = 0;

    for (const donor of donors) {
        // FoodDonation.donorId stores the User id.
        const result = await prisma.foodDonation.updateMany({
            where: { donorId: donor.user.id },
            data: {
                latitude: donor.latitude,
                longitude: donor.longitude
            }
        });

        updatedDonations += result.count;

        console.log(
            `${donor.customUserId}: ${result.count} donation(s) set to ` +
            `${donor.latitude ?? 'null'}, ${donor.longitude ?? 'null'}`
        );
    }

    console.log(
        `Done. Synced ${updatedDonations} donation(s) for ` +
        `${donors.length} donor profile(s).`
    );
};

main()
    .catch((error) => {
        console.error('Failed to sync donation locations:', error);
        process.exitCode = 1;
    })
    .finally(() => prisma.$disconnect());
