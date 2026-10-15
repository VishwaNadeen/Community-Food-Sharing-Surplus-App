import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

export const getNgoCoordinatorProfile = async (customUserId: string) => {
    const user = await prisma.user.findUnique({
        where: { customUserId },
        select: { firstName: true, lastName: true, profileImageUrl: true }
    });
    if (!user) throw new Error('Coordinator account not found');
    return user;
};

export const updateNgoCoordinatorProfile = async (
    customUserId: string,
    firstName: string,
    lastName: string
) => {
    const first = firstName.trim();
    const last = lastName.trim();
    if (!first || !last) throw new Error('First name and last name are required');

    return prisma.user.update({
        where: { customUserId },
        data: { firstName: first, lastName: last },
        select: { firstName: true, lastName: true, profileImageUrl: true }
    });
};

export const updateNgoCoordinatorPhoto = async (
    customUserId: string,
    profileImageUrl: string
) => prisma.user.update({
    where: { customUserId },
    data: { profileImageUrl },
    select: { firstName: true, lastName: true, profileImageUrl: true }
});
